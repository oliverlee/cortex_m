"""
extension for performing local configuration
"""

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

def _local_config_impl(_mctx):
    _local_workspace_directories(
        name = "local_workspace_directories",
    )

local_config = module_extension(
    implementation = _local_config_impl,
)
