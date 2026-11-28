"""
extension for loading packages from a flake
"""

# The Nix daemon ignores these options, with a warning, unless the user is in
# trusted-users.
_CACHIX_NIXOPTS = [
    "--option",
    "extra-substituters",
    "https://oliverlee.cachix.org",
    "--option",
    "extra-trusted-public-keys",
    "oliverlee.cachix.org-1:58fy+wCReIwjmQiTslvrmWkNrQwbhpuoqqelrwGyzf8=",
]

# Building a package that isn't cached, e.g. `qemu-system-arm`, can take longer
# than the 10 minute default timeout of `repository_ctx.execute`.
_BUILD_TIMEOUT_SECONDS = 30 * 60

_FLAKE_FILE = Label("//tools/nix:flake.nix")
_FLAKE_LOCK_FILE = Label("//tools/nix:flake.lock")
_PINS = Label("//tools/nix:pins.json")
_PINS_NIX = Label("//tools/nix:pins.nix")

# Evaluates to the pinned store path of each package for this system. Fails if
# the pins don't match the flake.
_PINNED_PATHS_EXPR = """
(import {pins_nix}).paths {{
  pinsFile = "{pins}";
  group = "packages";
  dir = "{flake_dir}";
}}
"""

def _nix(ctx, args, *, timeout = 600):
    nix = ctx.which("nix")
    if not nix:
        fail("`nix` not found on the PATH. See https://nixos.org/download/")

    return ctx.execute(
        [nix, "--extra-experimental-features", "nix-command flakes"] + args,
        timeout = timeout,
    )

def _last_line(stderr):
    # The last line of the stderr of `nix` is the error. Earlier lines are
    # usually warnings, e.g. about untrusted substituters. stderr may be empty.
    return (stderr.strip().splitlines() or [""])[-1]

def _pinned_paths(mctx):
    """Returns the pinned store path of each package for this system.

    Args:
      mctx: The module context.

    Returns:
      A dict from package name to store path, empty if the pins are stale.
    """
    for label in [_FLAKE_FILE, _FLAKE_LOCK_FILE, _PINS, _PINS_NIX]:
        mctx.watch(label)

    result = _nix(mctx, [
        "eval",
        "--impure",
        "--json",
        "--expr",
        _PINNED_PATHS_EXPR.format(
            flake_dir = mctx.path(_FLAKE_FILE).dirname,
            pins = mctx.path(_PINS),
            pins_nix = mctx.path(_PINS_NIX),
        ),
    ])
    if result.return_code != 0:
        # buildifier: disable=print
        print("building flake packages from the flake: {}".format(
            _last_line(result.stderr),
        ))
        return {}

    return json.decode(result.stdout)

def _copy_flake(rctx, dest):
    """Copies the flake files into `dest`.

    A `path:` flake can't use a path with a symlink in it, e.g. a module added
    with `local_path_override`. Each file keeps its path relative to the package
    of `flake_file`.

    Args:
      rctx: The repository context.
      dest: Directory in the repository to copy the files into.

    Returns:
      The directory of the copied flake.
    """
    flake = rctx.attr.flake_file
    for src in [flake, rctx.attr.flake_lock_file] + rctx.attr.data:
        if src.repo_name != flake.repo_name or src.package != flake.package:
            fail("{} is not in the package of {}".format(src, flake))
        rctx.file(
            "{}/{}".format(dest, src.name),
            rctx.read(src),
            executable = False,
        )

    return rctx.path("{}/{}".format(dest, flake.name)).realpath.dirname

def _realise(rctx, out_link):
    """Fetches the pinned store path of the package, or builds the package.

    Args:
      rctx: The repository context.
      out_link: Path of the out link to create in the repository.

    Returns:
      The store path of the `out` output of the package.
    """
    if rctx.attr.store_path:
        fetched = _nix(
            rctx,
            ["build", "--out-link", out_link, rctx.attr.store_path] +
            _CACHIX_NIXOPTS,
        )
        if fetched.return_code == 0:
            return rctx.path(out_link).realpath
        reason = _last_line(fetched.stderr)
    else:
        reason = "no pinned store path"

    # buildifier: disable=print
    print("building {} from the flake: {}".format(rctx.attr.package, reason))

    flake_dir = _copy_flake(rctx, "bazel-support/flake")
    built = _nix(
        rctx,
        [
            "build",
            "--out-link",
            out_link,
            "path:{}#{}".format(flake_dir, rctx.attr.package),
        ] + _CACHIX_NIXOPTS,
        timeout = _BUILD_TIMEOUT_SECONDS,
    )
    if built.return_code != 0:
        fail("failed to build {}:\n{}".format(rctx.attr.package, built.stderr))

    return rctx.path(out_link).realpath

def _flake_package_impl(rctx):
    # The out link keeps Nix from garbage collecting the store path until the
    # repository is deleted.
    store_path = _realise(rctx, "bazel-support/nix-out-link")

    for child in store_path.readdir():
        rctx.symlink(child, child.basename)

    rctx.file("BUILD.bazel", rctx.attr.build_file_content, executable = False)

_flake_package = repository_rule(
    implementation = _flake_package_impl,
    attrs = {
        "build_file_content": attr.string(mandatory = True),
        "data": attr.label_list(
            doc = (
                "Other files in the package of `flake_file` that evaluating " +
                "the flake reads, e.g. the files of a `path:` input"
            ),
        ),
        "flake_file": attr.label(mandatory = True),
        "flake_lock_file": attr.label(mandatory = True),
        "package": attr.string(mandatory = True),
        "store_path": attr.string(
            doc = "Pinned store path of the package, fetched from a binary cache",
        ),
    },
    doc = (
        "Symlinks the outputs of a flake package, fetching its pinned store " +
        "path from a binary cache or building it from the flake"
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

def _provide_binary(mctx, pkgs):
    pinned_paths = _pinned_paths(mctx)

    for package in pkgs:
        if type(package) != "dict":
            package = {"name": package}

        defaults = {
            "build_file_content": _native_binary_build_file_content(package["name"]),
            "data": [
                "//tools/nix:bazel-wrapper/flake.lock",
                "//tools/nix:bazel-wrapper/flake.nix",
            ],
            "flake_file": _FLAKE_FILE,
            "flake_lock_file": _FLAKE_LOCK_FILE,
            "package": package["name"],
            "store_path": pinned_paths.get(package["name"], ""),
        }

        _flake_package(
            **(defaults | package)
        )

    return mctx.extension_metadata(reproducible = True)

def _flake_package_deps_impl(mctx):
    return _provide_binary(mctx, [
        "diff",
        "gdb",
        "qemu-system-arm",
    ])

flake_package_deps = module_extension(
    implementation = _flake_package_deps_impl,
)

def _flake_package_dev_deps_impl(mctx):
    return _provide_binary(mctx, [
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
