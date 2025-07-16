Build

```sh
bazel build //examples/semihosting \
  --platforms=@stm32//platforms:lm3s6965evb
```

Run under qemu (installed on the host)

```sh
bazel run //examples/semihosting \
 --platforms=@stm32//platforms:lm3s6965evb \
 --run_under=//tools/qemu:semihosting
```
