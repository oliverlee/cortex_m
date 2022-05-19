Use a modern formatting library.

It's pretty big though: https://github.com/fmtlib/fmt/issues/2108

Build

```sh
bazel build //examples/fmt \
  --platforms=@stm32//platforms:lm3s6965evb
```

Run under qemu (installed on the host)

```sh
bazel run //examples/fmt \
 --platforms=@stm32//platforms:lm3s6965evb \
 --run_under=//tools/qemu:semihosting
```
