run with

```sh
bazel run \
  --platforms=@bazel_stm32//platform:lm3s6965evb \
  --run_under=@bazel_stm32//:qemu_runner \
  --@bazel_stm32//config:semihosting \
  //semihosting:binary
```

or

```sh
bazel run \
  --platforms=@bazel_stm32//platform:lm3s6965evb \
  --run_under=@bazel_stm32//:qemu_runner \
  //semihosting:semihosting
```
or

```sh
bazel run \
  --run_under=@bazel_stm32//:qemu_runner    \
  //semihosting:semihosting.lm3s6965evb
```
