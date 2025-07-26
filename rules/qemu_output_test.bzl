"""
compare the output for a binary run in QEMU
"""

load("@rules_cc//cc:defs.bzl", "cc_binary")
load("//rules:binary_log.bzl", "binary_log_test")
load("//rules:transitions.bzl", "transition_config_binary")

def qemu_output_test(
        *,
        name,
        srcs,
        expected_output,
        platform,
        run_under = "//:qemu_runner",
        diff = "diff -u --color=always --strip-trailing-cr",
        **kwargs):
    cc_binary(
        name = name + ".binary",
        srcs = srcs,
        tags = ["manual"],
        visibility = ["//visibility:private"],
    )

    transition_config_binary(
        name = name + ".transition",
        src = name + ".binary",
        platform = platform,
        semihosting = "enabled",
        tags = ["manual"],
        visibility = ["//visibility:private"],
    )

    binary_log_test(
        name = name,
        src = name + ".transition",
        expected_stdout = expected_output,
        run_under = run_under,
        diff = diff,
        **kwargs
    )
