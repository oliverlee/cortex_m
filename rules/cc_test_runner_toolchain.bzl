"""
CcTestRunnerToolchain that executes a test binary using a custom test runner.

adapted from:
https://github.com/bazel-contrib/musl-toolchain/blob/054f2f36b4aa42d3e358cbf0afce993c9bb3b1ba/musl_cc_toolchain_config.bzl

CcTestRunnerToolchain is used here:
https://github.com/bazelbuild/bazel/blob/20cf927d8ce4e3fbd29d7bb45c5037b4fea49da8/src/main/starlark/builtins_bzl/common/cc/cc_test.bzl#L63-L79
"""

_CcTestInfo = provider(
    doc = "Toolchain implementation for @bazel_tools//tools/cpp:test_runner_toolchain_type",
    fields = {
        "get_runner": "Callback invoked by cc_test, should accept (ctx, binary_info, processed_environment, test_runner) and return a list of providers",
        "linkopts": "Additional linkopts from an external source (e.g. toolchain)",
        "linkstatic": "If set, force this to be linked statically (i.e. --dynamic_mode=off)",
    },
)

_CcTestRunnerInfo = provider(
    doc = "Test runner implementation for @bazel_tools//tools/cpp:test_runner_toolchain_type",
    fields = {
        "args": "kwargs to pass to the test runner function",
        "func": "The test runner function with signature (ctx, binary_info, processed_environment, **kwargs)",
    },
)

def _cc_test_runner_runner_func(
        ctx,
        binary_info,
        processed_environment,
        test_runner):
    executable = ctx.actions.declare_file(ctx.label.name + "_test_runner.bash")

    ctx.actions.write(
        output = executable,
        content = """
#!/usr/bin/env bash
set -euo pipefail

exec '{test_runner}' '{binary}' "$@"
""".format(
            test_runner = test_runner.files_to_run.executable.short_path,
            binary = binary_info.executable.short_path,
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles().merge_all([
        ctx.runfiles([test_runner.files_to_run.executable, binary_info.executable]),
        binary_info.runfiles,
    ] + [
        files
        for files in [
            test_runner[DefaultInfo].default_runfiles,
            test_runner[DefaultInfo].data_runfiles,
        ]
        if files
    ])

    return [
        DefaultInfo(
            executable = executable,
            files = binary_info.files,
            runfiles = runfiles,
        ),
        RunEnvironmentInfo(
            environment = processed_environment,
            inherited_environment = ctx.attr.env_inherit,
        ),
    ]

def _cc_test_runner_toolchain_impl(ctx):
    cc_test_runner_info = _CcTestRunnerInfo(
        args = {
            "test_runner": ctx.attr.test_runner,
        },
        func = _cc_test_runner_runner_func,
    )
    cc_test_info = _CcTestInfo(
        get_runner = cc_test_runner_info,
        linkopts = [],
        linkstatic = True,
    )
    return [
        platform_common.ToolchainInfo(
            cc_test_info = cc_test_info,
        ),
    ]

cc_test_runner_toolchain = rule(
    implementation = _cc_test_runner_toolchain_impl,
    attrs = {
        "test_runner": attr.label(
            allow_single_file = True,
            executable = True,
            mandatory = True,
            cfg = "exec",
            doc = "Binary used to run the test executable",
        ),
    },
)
