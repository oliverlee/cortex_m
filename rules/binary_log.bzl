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

def _binary_log_impl(ctx):
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
    implementation = _binary_log_impl,
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

def _binary_log_test_impl(ctx):
    if (
        not (ctx.attr.expected_stdout or ctx.attr.expected_stderr) and
        not ctx.attr.skip_expected_check
    ):
        fail(
            "At least one of 'expected_stdout' or 'expected_stderr' must be " +
            "provided. Or expected output checks can be skipped by setting " +
            "'skip_expected_check'.",
        )

    if (
        ctx.attr.skip_expected_check and
        (ctx.attr.expected_stdout or ctx.attr.expected_stderr)
    ):
        fail(
            "Cannot use 'skip_expected_check' if either 'expected_stdout' " +
            "or 'expected_stderr' are provided.",
        )

    if (bool(ctx.attr.logs) == bool(ctx.attr.src)):
        fail("Only one of 'logs' or 'src' must be provided.")

    if ctx.attr.run_under and not ctx.attr.src:
        fail("'run_under' may only used if 'src' is provided.")

    logs = ctx.attr.logs[LoggingInfo] if ctx.attr.logs else _binary_log_impl(ctx)[1]

    content = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "",
        "exit_code=0",
    ]
    paths = {}
    runfiles = []

    for fd in ["stdout", "stderr"]:
        if getattr(ctx.file, "expected_" + fd):
            expected_file = getattr(ctx.file, "expected_" + fd)
            actual_file = getattr(logs, fd)

            content += [
                line.format(
                    fd = fd,
                    diff = ctx.attr.diff,
                )
                for line in [
                    "",
                    "echo '--- {fd} ---'",
                    "{diff} {{expected_{fd}}} {{actual_{fd}}} || exit_code=1",
                    "echo '--------------'",
                ]
            ]
            paths |= {
                "expected_" + fd: expected_file.short_path,
                "actual_" + fd: actual_file.short_path,
            }
            runfiles += [
                expected_file,
                actual_file,
            ]

    content.append("exit $exit_code")

    executable = ctx.actions.declare_file(ctx.label.name + ".bash")
    ctx.actions.write(
        output = executable,
        content = "\n".join(content).format(**paths),
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = ctx.runfiles(files = runfiles),
        ),
        RunEnvironmentInfo(
            environment = ctx.attr.env,
            inherited_environment = [],
        ),
    ]

binary_log_test = rule(
    implementation = _binary_log_test_impl,
    attrs = {
        "logs": attr.label(
            doc = "Log files to compare with",
            providers = [LoggingInfo],
        ),
        "src": attr.label(
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
        "expected_stdout": attr.label(
            allow_single_file = True,
            doc = "Expected stdout of the binary. If 'None', 'stdout' is not tested.",
        ),
        "expected_stderr": attr.label(
            allow_single_file = True,
            doc = "Expected stdout of the binary. If 'None', 'stderr' is not tested.",
        ),
        "skip_expected_check": attr.bool(
            default = False,
            doc = (
                "Skip expected output checks. Can be used to define a test " +
                "with a custom QEMU runner."
            ),
        ),
        "env": attr.string_dict(
            doc = (
                "Environment variables set when comparing files. The same env " +
                "is used if this rule also executes the binary."
            ),
        ),
        "diff": attr.string(
            default = "diff -u --color=always",
            doc = "Diff command used to compare files.",
        ),
    },
    test = True,
)
