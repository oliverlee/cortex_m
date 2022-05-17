Build the target, then pass it to gdb:

```sh
bazel run //examples:main \
  --platforms=@stm32//platforms:lm3s6965evb \
  --run_under=@arm_none_eabi//:gdb \
  -c dbg
```

Launch qemu, after building the binary first

```sh
qemu-system-arm \
  -machine lm3s6965evb \
  -gdb tcp::3333 \
  -S \
  -kernel bazel-bin/examples/main
```

