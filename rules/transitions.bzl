"""
Rule to transition the semihosting configuration of a binary
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:debug_package_info.bzl", "DebugPackageInfo")

_semihosting_transition = transition(
    implementation = lambda _settings, attr: {
        "//config:semihosting": {"enabled": True, "disabled": False}[attr.semihosting],
    },
    inputs = [],
    outputs = [
        "//config:semihosting",
    ],
)

def _transition_semihosting_binary_impl(ctx):
    target = ctx.attr.src
    default_info = target[DefaultInfo]

    binary = default_info.files_to_run.executable
    runfiles = default_info.default_runfiles
    if default_info.data_runfiles:
        runfiles = runfiles.merge(default_info.data_runfiles)

    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = out,
        target_file = binary,
    )

    return [
        DefaultInfo(
            executable = out,
            runfiles = runfiles,
        ),
    ] + [
        target[provider]
        for provider in [
            CcInfo,
            DebugPackageInfo,
            OutputGroupInfo,
            InstrumentedFilesInfo,
            RunEnvironmentInfo,
        ]
        if provider in target
    ]

transition_semihosting_binary = rule(
    implementation = _transition_semihosting_binary_impl,
    cfg = _semihosting_transition,
    attrs = {
        "src": attr.label(
            mandatory = True,
            providers = [CcInfo],
            doc = "The binary to transition",
        ),
        "semihosting": attr.string(
            values = ["enabled", "disabled"],
            mandatory = True,
            doc = "Enable or disable semihosting",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
)
