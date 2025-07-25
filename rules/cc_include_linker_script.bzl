"""
Rule to include a non-primary linker script in a C++ target.
"""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _impl(ctx):
    files = []
    flags = []
    for src in ctx.attr.srcs:
        files.append(src.files)

        for f in src.files.to_list():
            flags.extend(["-L", f.dirname])

    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        additional_inputs = depset(transitive = files),
        user_link_flags = flags,
    )

    linking_context = cc_common.create_linking_context(
        linker_inputs = depset([linker_input]),
    )

    return [
        DefaultInfo(
            files = depset(transitive = files),
        ),
        CcInfo(
            linking_context = linking_context,
        ),
    ]

cc_include_linker_script = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
    },
    provides = [CcInfo],
)
