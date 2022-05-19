Examples for building for stm32 with Bazel

# running with `qemu`
An elf can be run under a host installation of `qemu-system-arm`:

```sh
bazel run //examples/semihosting \
  --platforms=@stm32//platforms:lm3s6965evb \
  --run_under=//tools/qemu:semihosting
```

If other options for qemu are necessary:

```sh
bazel run <target> \
  --platforms=@arm_none_eabi//platforms:cortex-m3 \
  --run_under="//tools/qemu -machine <machine> -gdb tcp::3333 -S"
```
