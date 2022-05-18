Build

```sh
bazel build //examples/semihosting \
  --platforms=@stm32//platforms:lm3s6965evb
```

Run

```sh
qemu-system-arm \
  -machine lm3s6965evb \
  -semihosting \
  -device loader,file=bazel-bin/examples/semihosting/semihosting
```
