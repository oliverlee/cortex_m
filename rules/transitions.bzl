"""
Rule to transition the semihosting configuration of a binary
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:debug_package_info.bzl", "DebugPackageInfo")

def _config_transition_impl(settings, attr):
    out = {} | settings

    if attr.semihosting:
        out["//config:semihosting"] = attr.semihosting == "enabled"

    if attr.platform:
        out["//command_line_option:platforms"] = [attr.platform]

    if attr.extra_toolchains:
        out["//command_line_option:extra_toolchains"] = attr.extra_toolchains

    return out

_config_transition = transition(
    implementation = _config_transition_impl,
    inputs = [
        "//config:semihosting",
        "//command_line_option:platforms",
        "//command_line_option:extra_toolchains",
    ],
    outputs = [
        "//config:semihosting",
        "//command_line_option:platforms",
        "//command_line_option:extra_toolchains",
    ],
)

def _transition_config_binary_impl(ctx):
    target = ctx.attr.src
    default_info = target[DefaultInfo]

    binary = default_info.files_to_run.executable
    runfiles = default_info.default_runfiles

    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = out,
        target_file = binary,
    )

    # `//config:machine` doesn't get propagated to the `run_under` arg so we
    # pass the machine option via RunEnvironmentInfo
    machine = ctx.attr._machine[BuildSettingInfo].value

    env = {
        "QEMU_MACHINE": machine,
    } if machine else {}

    inherit_env = []
    if RunEnvironmentInfo in target:
        env = target[RunEnvironmentInfo].environment | env
        inherit_env = target[RunEnvironmentInfo].inherited_environment

    return [
        DefaultInfo(
            executable = out,
            runfiles = runfiles,
        ),
        RunEnvironmentInfo(
            environment = env,
            inherited_environment = inherit_env,
        ),
    ] + [
        target[provider]
        for provider in [
            CcInfo,
            DebugPackageInfo,
            OutputGroupInfo,
            InstrumentedFilesInfo,
        ]
        if provider in target
    ]

def _common_attrs(*, default = {}):
    return {
        "src": attr.label(
            mandatory = True,
            providers = [CcInfo],
            default = default.get("src", None),
            doc = "The binary to transition",
        ),
        "semihosting": attr.string(
            values = ["enabled", "disabled"],
            default = default.get("semihosting", ""),
            doc = "Enable or disable semihosting or leave it unchanged if `None`",
        ),
        "platform": attr.label(
            default = default.get("platform", None),
            doc = "Target platform for the binary",
        ),
        "extra_toolchains": attr.label_list(
            default = default.get("extra_toolchains", []),
            doc = "Extra toolchains to use with the binary",
        ),
        "_machine": attr.label(
            default = "//config:machine",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    }

transition_config_binary = rule(
    implementation = _transition_config_binary_impl,
    cfg = _config_transition,
    attrs = _common_attrs(),
    executable = True,
    provides = [DefaultInfo, RunEnvironmentInfo, CcInfo],
)

transition_config_test = rule(
    implementation = _transition_config_binary_impl,
    cfg = _config_transition,
    attrs = _common_attrs(
        default = {
            # semihosting should always be enabled for tests
            "semihosting": "enabled",
        },
    ),
    test = True,
    provides = [DefaultInfo, RunEnvironmentInfo, CcInfo],
)
