run with

```sh
bazel run \
  --platforms=@cortex_m//platform:lm3s6965evb \
  --run_under=@cortex_m//:qemu_runner \
  --@cortex_m//config:semihosting \
  //semihosting:binary
```

or

```sh
bazel run \
  --platforms=@cortex_m//platform:lm3s6965evb \
  --run_under=@cortex_m//:qemu_runner \
  //semihosting:semihosting
```

or

```sh
bazel run \
  --run_under=@cortex_m//:qemu_runner \
  //semihosting:semihosting.lm3s6965evb
```

or

```sh
bazel run \
  --run_under=@cortex_m//:gdb_qemu_runner \
  -c dbg \
  //semihosting:semihosting.lm3s6965evb
```
