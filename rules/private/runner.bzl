"""
Utility functions for runner rules.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

visibility("//...")

runfiles_init = """
# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{ echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---
"""

def load_config(attrs):
    """
    Load configuration from attributes.

    Args:
      attrs:
        `attr` field of the rule `ctx` paramter

    Returns:
      A struct which contains a entry per configuration option present in
      `attrs`.
    """
    cfg = {}

    if hasattr(attrs, "_semihosting"):
        cfg["semihosting"] = attrs._semihosting[BuildSettingInfo]

    if hasattr(attrs, "_machine"):
        cfg["machine"] = attrs._machine[BuildSettingInfo].value

    return struct(**cfg)

def rlpath(target):
    """
    Returns the rlocation input path of a target.

    This path can be used as the first argument to `rlocation`.
    """
    label = target.label

    return "/".join([
        part
        for part in [
            label.workspace_name or "_main",
            label.package,
            label.name,
        ]
        if part
    ])
