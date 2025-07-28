Build the target, then pass it to gdb:

```sh
bazel run \
  --platforms=@bazel_stm32//platform:lm3s6965evb \
  --run_under=@@toolchains_arm_gnu++arm_toolchain+arm_none_eabi_darwin_arm64//:bin/arm-none-eabi-gdb \
  -c dbg \
  //minimal
```

gdb is not yet connected to anything.

In another terminal, run the target with qemu:

```sh
 bazel run \
    --platforms=@bazel_stm32//platform:lm3s6965evb \
    --run_under=@bazel_stm32//:qemu_runner \
    -c dbg \
    //minimal -- \
    -s -S
```

Connect with gdb:
```sh
(gdb) target remote :1234
(gdb) directory <workspace-root>
(gdb) b main
(gdb) c
```
