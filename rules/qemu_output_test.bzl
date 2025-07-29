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
        platform,
        expected_stdout = None,
        expected_stderr = None,
        local_defines = None,
        copts = None,
        run_under = "//:qemu_runner",
        diff = "diff -u --color=always --strip-trailing-cr",
        **kwargs):
    cc_binary(
        name = name + ".binary",
        srcs = srcs,
        local_defines = local_defines,
        copts = copts,
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
        expected_stdout = expected_stdout,
        expected_stderr = expected_stderr,
        run_under = run_under,
        diff = diff,
        **kwargs
    )
