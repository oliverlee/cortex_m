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
    rctx.repo_metadata(reproducible = True)

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

def _native_binary_build_file_content(binary, *, package = None):
    return """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "{package}",
    out = "{binary}",
    src = "bin/{binary}",
    visibility = ["//visibility:public"],
)
""".format(
        binary = binary,
        package = package or binary,
    )

def _provide_binary(pkgs):
    _flake_copy(
        name = "flake_copy",
        flake_file = "//extensions:flake.nix",
        flake_lock_file = "//extensions:flake.lock",
    )

    for package in pkgs:
        if type(package) != "dict":
            package = {"name": package}

        defaults = {
            "nix_flake_file": "@flake_copy//:flake.nix",
            "nix_flake_lock_file": "@flake_copy//:flake.lock",
            "package": package["name"],
            "build_file_content": _native_binary_build_file_content(package["name"]),
        }

        nixpkgs_flake_package(
            **(defaults | package)
        )

def _flake_package_deps_impl(_mctx):
    _provide_binary([
        "gdb",
        {
            "name": "qemu-system-arm",
            "package": "qemu",
        },
    ])

flake_package_deps = module_extension(
    implementation = _flake_package_deps_impl,
)

def _flake_package_dev_deps_impl(_mctx):
    _provide_binary([
        {
            "name": "glibc",
            "build_file_content": """
filegroup(
  name = "sysroot",
  srcs = glob(["*/**"]),
  visibility = ["//visibility:public"],
)
            """,
        },
        "nixd",
        "nixfmt",
        {
            "name": "nixfmt-tree",
            "build_file_content": _native_binary_build_file_content(
                package = "nixfmt-tree",
                binary = "treefmt",
            ),
        },
    ])

flake_package_dev_deps = module_extension(
    implementation = _flake_package_dev_deps_impl,
)
