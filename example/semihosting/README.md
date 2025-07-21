run with

```sh
bazel run \
  --platforms=//platform:lm3s6965evb \
  --run_under=//:qemu_runner \
  --//config:semihosting \
  //example/semihosting:binary
```

or

```sh
bazel run \
  --platforms=//platform:lm3s6965evb \
  --run_under=//:qemu_runner \
  //example/semihosting:semihosting
```
or

```sh
bazel run \
  --run_under=//:qemu_runner    \
  //example/semihosting:semihosting.lm3s6965evb
```
