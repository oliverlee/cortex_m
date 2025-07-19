"""
extension for loading packages from a flake
"""

load("@rules_nixpkgs_core//:nixpkgs.bzl", "nixpkgs_flake_package")

def _flake_package_deps_impl(_mctx):
    nixpkgs_flake_package(
        name = "qemu-system-arm",
        nix_flake_file = "//:flake.nix",
        nix_flake_lock_file = "//:flake.lock",
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
