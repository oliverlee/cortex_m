Examples for building for stm32 with Bazel

# building

An elf can be built for a target platform by specifying the platform

```sh
bazel build \
  --platforms=@stm32//platform:lm3s6965evb \
  //example/minimal
```

# running with `qemu`

An elf can be run with `qemu-system-arm`. This requires an installation of `nix`
to download the `qemu` package.

```sh
bazel run \
  --run_under=//:qemu_runner \
  --platforms=//platform:lm3s6965evb \
  //example/semihosting
```

By default, the QEMU runner accepts GDB connections on port 1234.

If other options for `qemu` are necessary:

```sh
bazel run \
  --run_under=//:qemu_runner \
  --platforms=//platform:lm3s6965evb \
  //example/semihosting -- <additional-args>
```

# enabling semihosting

By default, semihosting is not enabled when building targets. It can be enabled
with bool flag `--//config:semihosting`.

```sh
bazel run \
  --run_under=//:qemu_runner \
  --platforms=//platform:lm3s6965evb \
  --//config:semihosting \
  //example/semihosting:binary
```

Alternatively, the `transition_semihosting_binary` can be used to transition a
binary target to always enable or disable semihosting.

```starlark
transition_semihosting_binary(
    name = "semihosting",
    src = ":binary",
    semihosting = "enabled",
)
```

# running tests with `qemu`

`cc_test` targets can be built for the target platform and run under emulation
with `qemu-system-arm`.

```sh
bazel test \
  --platforms=//platform:lm3s6965evb \
  --extra_toolchains=//:qemu_test_runner_toolchain \
  --//config:semihosting \
  //...
```
