run with

```sh
bazel run \
  --platforms=//platform:lm3s6965evb \
  --run_under=//tools/qemu:lm3s6965evb_runner \
  --//toolchain:semihosting=True \
  //example/semihosting
```
