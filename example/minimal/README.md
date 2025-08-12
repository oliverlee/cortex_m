Build the target, then pass it to gdb:

```sh
bazel run \
  --platforms=@cortex_m//platform:lm3s6965evb \
  --run_under=@cortex_m//:gdb \
  -c dbg \
  //minimal
```

gdb is not yet connected to anything.

In another terminal, run the target with qemu:

```sh
 bazel run \
    --platforms=@cortex_m//platform:lm3s6965evb \
    --run_under=@cortex_m//:qemu_runner \
    -c dbg \
    //minimal -- \
    -s -S
```

Connect with gdb:
```sh
(gdb) target remote :1234
(gdb) directory <workspace-root>
(gdb) b main
(gdb) c
```
