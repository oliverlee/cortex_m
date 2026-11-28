#!/usr/bin/env bash
set -euo pipefail

# Fails if pins.json differs from the generated pins. $DIFF is `diff`, which
# isn't on the PATH of tools/bazel.

if ! "$DIFF" --color=always -u tools/nix/pins.json tools/nix/pins.generated.json; then
  echo "Run \`bazel run //tools/nix:pins.update\` to update pins.json." >&2
  exit 1
fi
