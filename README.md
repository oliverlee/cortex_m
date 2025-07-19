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
