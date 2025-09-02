"""
run QEMU for a specific machine
"""

load("//rules/private:runner.bzl", "load_config", "rlpath", "runfiles_init")

def _impl(ctx):
    cfg = load_config(ctx.attr)

    out = ctx.actions.declare_file(ctx.label.name)

    fixed_args = [
        "-display none",
    ] if ctx.attr.enable_default_args else []
    if cfg.semihosting:
        fixed_args.append("-semihosting-config enable=on,target=auto")
    if cfg.machine:
        fixed_args.append("-machine " + cfg.machine)
    fixed_args.extend(ctx.attr.extra_args)

    ctx.actions.write(
        output = out,
        content = """
#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
    echo "usage: bazel run {label} <binary> [additional-qemu-args...]"
    echo ""
    echo "Run a binary with QEMU {for_machine}"
    echo ""
    echo "Arguments:"
    echo "  <binary>                  Path to the binary/ELF file to run"
    echo "  [additional-qemu-args...] Additional arguments to pass to QEMU"
    echo ""
    echo "Examples:"
    echo "  bazel run {label} <binary>"
    echo "  bazel run {label} <binary> -S"
    echo "  bazel run {label} <binary> -semihosting-config enable=on,target=auto"
    exit 1
fi

{runfiles_init}

binary="$1"

args=({fixed_args} "-device" "loader,file=$binary")
args+=("${{@:2}}")

[[ -n "${{QEMU_MACHINE:-}}" ]] && args+=("-machine" "$QEMU_MACHINE")

exit_code=0
$(rlocation {qemu_system_arm}) "${{args[@]}}" || exit_code=$?
if ((exit_code != {exit_code})); then
    printf "ERROR: QEMU exited with \'$exit_code\' but " >&2
    printf "this runner expected '{exit_code}'\n" >&2
    exit 1
fi
""".format(
            fixed_args = " ".join(fixed_args),
            label = str(ctx.label).replace("@@", "@").replace("@//", "//"),
            for_machine = ("for " + cfg.machine) if cfg.machine else "",
            runfiles_init = runfiles_init,
            qemu_system_arm = rlpath(ctx.attr._qemu_system_arm),
            exit_code = ctx.attr.exit_code,
        ),
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = out,
            runfiles = ctx.runfiles(
                files = [ctx.executable._qemu_system_arm],
                transitive_files = ctx.attr._runfiles.files,
            ),
        ),
        RunEnvironmentInfo(
            environment = ctx.attr.env,
            inherited_environment = [],
        ),
    ]

qemu_runner = rule(
    implementation = _impl,
    attrs = {
        "extra_args": attr.string_list(
            default = [],
            doc = "Extra arguments to pass to QEMU",
        ),
        "enable_default_args": attr.bool(
            default = True,
            doc = "Enable default arguments passed to QEMU",
        ),
        "env": attr.string_dict(
            doc = "Environment variables set when running QEMU",
        ),
        "exit_code": attr.int(
            default = 0,
            doc = "Exit code of the QEMU process for success",
        ),
        "_qemu_system_arm": attr.label(
            default = "@qemu-system-arm",
            executable = True,
            cfg = "exec",
        ),
        "_machine": attr.label(
            default = "//config:machine",
        ),
        "_semihosting": attr.label(
            default = "//config:semihosting",
        ),
        "_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
    },
    executable = True,
    provides = [DefaultInfo, RunEnvironmentInfo],
)
