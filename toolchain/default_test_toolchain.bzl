"""
Test toolchain that runs bare-metal tests on the host.
"""

load("@local_bazel_version//:defs.bzl", "BAZEL_VERSION")
load("@platforms//host:constraints.bzl", "HOST_CONSTRAINTS")

visibility("private")

def _bazel_major_version():
    version = BAZEL_VERSION

    # Development builds report an empty version; treat them as the newest.
    if not version:
        return None
    return int(version.split(".")[0])

def default_test_toolchain(*, name, target_compatible_with, **kwargs):
    """
    Defines a `default_test_toolchain_type` toolchain for bare-metal targets.

    Bazel 9 requires a `@bazel_tools//tools/test:default_test_toolchain_type`
    toolchain for every test. The default one requires an execution platform
    with all of the target platform's constraints, and no execution platform
    has bare-metal constraints, even though tests run on the host under QEMU.
    This toolchain matches `target_compatible_with` and runs tests on the host,
    where QEMU from Nix runs.

    Bazel 8 doesn't have `default_test_toolchain_type`. On Bazel 8, `name` is
    a toolchain that matches no target platform. This lets
    `register_toolchains` name the target on any Bazel version.

    Args:
      name: name of the
        [`toolchain`](https://bazel.build/reference/be/platforms-and-toolchains#toolchain)
        target
      target_compatible_with: constraints of the target platforms whose tests
        run on the host, e.g. a board
      **kwargs: additional arguments passed to `toolchain`
    """
    major_version = _bazel_major_version()
    if major_version != None and major_version < 9:
        native.toolchain(
            name = name,
            target_compatible_with = ["@platforms//:incompatible"],
            toolchain = Label("//:qemu_cc_test_runner_toolchain"),
            toolchain_type = "@bazel_tools//tools/cpp:test_runner_toolchain_type",
            **kwargs
        )
        return

    native.toolchain(
        name = name,
        exec_compatible_with = HOST_CONSTRAINTS,
        target_compatible_with = target_compatible_with,
        toolchain = "@bazel_tools//tools/test:empty_toolchain",
        toolchain_type = "@bazel_tools//tools/test:default_test_toolchain_type",
        **kwargs
    )
