"""
run QEMU for a specific machine
"""

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name)

    fixed_args = [
        "-display none",
        "-machine " + ctx.attr.machine,
    ]
    if ctx.attr.gdb:
        fixed_args.append("-gdb " + ctx.attr.gdb)
    fixed_args.extend(ctx.attr.extra_args)

    ctx.actions.write(
        output = out,
        content = """
#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
    echo "usage: bazel run {label} <binary> [additional-qemu-args...]"
    echo ""
    echo "Run binary with QEMU for machine {machine}"
    echo ""
    echo "Arguments:"
    echo "  <binary>                  Path to the binary/ELF file to run"
    echo "  [additional-qemu-args...] Additional arguments to pass to QEMU"
    echo ""
    echo "Examples:"
    echo "  bazel run {label} <binary>"
    echo "  bazel run {label} <binary> -S"
    echo "  bazel run {label} <binary> -semihosting"
    exit 1
fi

binary="$1"

exec qemu-system-arm \
    {fixed_args} \
    -device loader,file="$binary" \
    "${{@:2}}"
""".format(
            fixed_args = " ".join(fixed_args),
            label = str(ctx.label).replace("@@", "@").replace("@//", "//"),
            machine = ctx.attr.machine,
        ),
        is_executable = True,
    )

    return [DefaultInfo(executable = out)]

qemu_runner = rule(
    implementation = _impl,
    attrs = {
        "machine": attr.string(
            mandatory = True,
            doc = "QEMU machine type",
        ),
        "gdb": attr.string(
            default = "tcp::1234",
            doc = "QEMU gdb port",
        ),
        "extra_args": attr.string_list(
            doc = "Extra arguments to pass to QEMU",
        ),
        # TODO remove dependency on system installed qemu-system-arm
    },
    executable = True,
)
