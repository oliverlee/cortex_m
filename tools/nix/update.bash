#!/usr/bin/env bash
set -euo pipefail

# Replaces tools/nix/pins.json with the generated pins.

cat tools/nix/pins.generated.json > "${BUILD_WORKSPACE_DIRECTORY}/tools/nix/pins.json"
