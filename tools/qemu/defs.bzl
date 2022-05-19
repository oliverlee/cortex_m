def _qemu_wrapper_impl(ctx):
    contents = """#!/bin/bash
set -euo pipefail

bin=qemu-system-arm
elf=${{@:$#}}
extra_args=${{@:1:$#-1}}

echo "using: $(which $bin)"
echo ""
$bin --version
echo ""
$bin \
  -device loader,file=$elf \
  {args} \
  $extra_args
"""
    local_args = []

    if ctx.files._board_memory:
        platform_board_dir = ctx.files._board_memory[0].dirname
        machine = platform_board_dir.partition("/")[-1]
        local_args.extend(["-machine {}".format(machine)])

    output = ctx.actions.declare_file("qemu_wrapper.sh")

    args = " ".join(ctx.attr.args + local_args)

    ctx.actions.write(
        output,
        contents.format(args = args),
        is_executable = True,
    )

    return [DefaultInfo(executable = output)]

qemu_wrapper = rule(
    implementation = _qemu_wrapper_impl,
    executable = True,
    attrs = {
        "_board_memory": attr.label(
            default = "@stm32//boards:maybe_memory_region",
        ),
    },
)
