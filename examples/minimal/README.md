Build the target, then pass it to gdb:

```sh
bazel run //examples/minimal \
  --platforms=@stm32//platforms:lm3s6965evb \
  --run_under=@arm_none_eabi//:gdb \
  -c dbg
```

gdb is not yet connected to anything.

In another terminal, launch qemu:

```sh
qemu-system-arm \
  -machine lm3s6965evb \
  -gdb tcp::3333 \
  -S \
  -device loader,file=bazel-bin/examples/minimal/minimal
```

Connect with gdb:
```sh
(gdb) target remote :3333
(gdb) b main
(gdb) c

```

