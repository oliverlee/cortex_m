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

def _native_binary_build_file_content(binary):
    return """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "{binary}",
    out = "{binary}",
    src = "bin/{binary}",
    visibility = ["//visibility:public"],
)
""".format(binary = binary)

def _flake_package_deps_impl(_mctx):
    _flake_copy(
        name = "flake_copy",
        flake_file = "//extensions:flake.nix",
        flake_lock_file = "//extensions:flake.lock",
    )

    nixpkgs_flake_package(
        name = "qemu-system-arm",
        nix_flake_file = "@flake_copy//:flake.nix",
        nix_flake_lock_file = "@flake_copy//:flake.lock",
        package = "qemu",
        build_file_content = _native_binary_build_file_content("qemu-system-arm"),
    )

    nixpkgs_flake_package(
        name = "gdb",
        nix_flake_file = "@flake_copy//:flake.nix",
        nix_flake_lock_file = "@flake_copy//:flake.lock",
        package = "gdb",
        build_file_content = _native_binary_build_file_content("gdb"),
    )

flake_package_deps = module_extension(
    implementation = _flake_package_deps_impl,
)
