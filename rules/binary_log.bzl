"""
log output for a binary executed on the host platform
"""

LoggingInfo = provider(
    doc = "Log output for a binary target",
    fields = {
        "stdout": "stdout of the executed binary target",
        "stderr": "stderr of the executed binary target",
    },
)

def _impl(ctx):
    stdout = ctx.actions.declare_file(ctx.label.name + ".stdout")
    stderr = ctx.actions.declare_file(ctx.label.name + ".stderr")

    runner = ctx.attr.run_under
    binary = ctx.attr.src

    runner_exe = [ctx.executable.run_under] if runner else []

    env = {}

    for attr in [runner, binary]:
        if attr and RunEnvironmentInfo in attr:
            env = env | attr[RunEnvironmentInfo].environment

    env = env | ctx.attr.env

    ctx.actions.run_shell(
        outputs = [stdout, stderr],
        inputs = [ctx.executable.src],
        tools = runner_exe,
        command = """
#!/usr/bin/env bash
set -uo pipefail

{command}
exit_code=$?

set -e

if ((exit_code != 0)); then
  echo "Command failed with exit code $exit_code" >&2
  echo "--- COMMAND ---" >&2
  echo "{command}" >&2
  echo "---------------" >&2

  if [[ -s "$2" ]]; then
    echo "--- STDOUT ---" >&2
    cat "$2" >&2
    echo "--------------" >&2
  fi

  if [[ -s "$3" ]]; then
    echo "--- STDERR ---" >&2
    cat "$3" >&2
    echo "--------------" >&2
  fi
fi

exit $exit_code
""".format(
            command = '{runner}"$1" > "$2" 2> "$3"'.format(
                runner = '"$4" ' if runner else "",
            ),
        ),
        arguments = [
            ctx.executable.src.path,
            stdout.path,
            stderr.path,
        ] + [
            exe.path
            for exe in runner_exe
        ],
        mnemonic = "Logging",
        progress_message = "Logging output of {}".format(
            str(ctx.label).replace("@@", "@").replace("@//", "//"),
        ),
        use_default_shell_env = True,
        env = env,
    )

    return [
        DefaultInfo(
            files = depset([stdout, stderr]),
        ),
        LoggingInfo(
            stdout = stdout,
            stderr = stderr,
        ),
    ]

binary_log = rule(
    implementation = _impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            executable = True,
            cfg = "target",
            doc = (
                "Binary to execute on the exec platform. This is built for " +
                "the target platform."
            ),
        ),
        "run_under": attr.label(
            executable = True,
            cfg = "exec",
            doc = (
                "Runner used to execute the binary. This is built for the " +
                "host platform."
            ),
        ),
        "env": attr.string_dict(
            doc = "Environment variables set when running the binary",
        ),
    },
    provides = [DefaultInfo],
)
