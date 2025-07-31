"""
extension for loading packages from a flake
"""

load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_flake_package")

def _flake_copy_impl(rctx):
    rctx.file(
        "flake.nix",
        rctx.read(rctx.path(rctx.attr.flake_file)),
        executable = False,
    )
    rctx.file(
        "flake.lock",
        rctx.read(rctx.path(rctx.attr.flake_lock_file)),
        executable = False,
    )
    rctx.file(
        "BUILD.bazel",
        """
exports_files(["flake.nix", "flake.lock"])
""",
        executable = False,
    )

_flake_copy = repository_rule(
    implementation = _flake_copy_impl,
    attrs = {
        "flake_file": attr.label(),
        "flake_lock_file": attr.label(),
    },
    doc = (
        "Copy a flake.nix and flake.lock file to the repository to avoid use of symlinks"
    ),
)

def _flake_package_deps_impl(_mctx):
    _flake_copy(
        name = "flake_copy",
        flake_file = "//:flake.nix",
        flake_lock_file = "//:flake.lock",
    )

    nixpkgs_flake_package(
        name = "qemu-system-arm",
        nix_flake_file = "@flake_copy//:flake.nix",
        nix_flake_lock_file = "@flake_copy//:flake.lock",
        package = "qemu",
        build_file_content = """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "qemu-system-arm",
    out = "qemu-system-arm",
    src = "bin/qemu-system-arm",
    visibility = ["//visibility:public"],
)
""",
    )

flake_package_deps = module_extension(
    implementation = _flake_package_deps_impl,
)

def _local_workspace_directories_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        content = """\
exports_files(["defs.bzl"])
        """,
        executable = False,
    )

    rctx.file(
        "defs.bzl",
        content = """
BAZEL_OUTPUT_BASE = "{output_base}"
BAZEL_WORKSPACE_ROOT = "{workspace_root}"
""".format(
            output_base = str(rctx.path(".").realpath)
                .removesuffix("/" + rctx.name)
                .removesuffix("/external"),
            workspace_root = rctx.workspace_root,
        ),
        executable = False,
    )

_local_workspace_directories = repository_rule(
    implementation = _local_workspace_directories_impl,
    local = True,
)

def _local_workspace_config_impl(_mctx):
    _local_workspace_directories(
        name = "local_workspace_directories",
    )

local_workspace_config = module_extension(
    implementation = _local_workspace_config_impl,
)
