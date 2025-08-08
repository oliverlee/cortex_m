"""Rules for running binaries in QEMU with GDB attached."""

load("@local_workspace_directories//:defs.bzl", "BAZEL_OUTPUT_BASE", "BAZEL_WORKSPACE_ROOT")
load("//rules/private:runner.bzl", "load_config", "rlpath", "runfiles_init")

def _impl(ctx):
    cfg = load_config(ctx.attr)

    out = ctx.actions.declare_file(ctx.label.name)

    gdb_args = (
        [
            "--silent",
            "-directory=" + BAZEL_WORKSPACE_ROOT,
            "-directory=" + BAZEL_OUTPUT_BASE,
            "--eval-command='target remote :1234'",
        ] if ctx.attr.enable_default_args else []
    )
    gdb_args.extend(ctx.attr.extra_args)

    ctx.actions.write(
        output = out,
        content = """
#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
    echo "usage: bazel run {label} <binary> [additional-gdb-args...]"
    echo ""
    echo "Run a binary with QEMU {for_machine} and connect to it with GDB"
    echo ""
    echo "Arguments:"
    echo "  <binary>                  Path to the binary/ELF file to run"
    echo "  [additional-gdb-args...] Additional arguments to pass to GDB"
    echo ""
    echo "Examples:"
    echo "  bazel run {label} <binary>"
    echo "  bazel run {label} <binary> -ex 'break main'"
    exit 1
fi

{runfiles_init}

binary="$1"
args=({gdb_args})
args+=("${{@:2}}")

runner_pid=$$
return=$(mktemp)
echo '0' > "$return"

echo "INFO: starting QEMU runner process..." >&2
$(rlocation {qemu_runner}) "$binary" &
qemu_pid=$!

{{
  while ps_stat=$(ps -p $qemu_pid -o stat=) && [[ "$ps_stat" != *Z* ]]; do
    sleep 0.1
  done

  # QEMU process does not exist or is a zombie
  echo '1' > "$return"
  pkill -P $runner_pid
}} &

echo "INFO: starting GDB..." >&2
$(rlocation {arm_none_eabi_gdb}) "${{args[@]}}" "$binary"

pkill -P $qemu_pid

exit $(cat "$return")
""".format(
            gdb_args = " ".join(gdb_args),
            label = str(ctx.label).replace("@@", "@").replace("@//", "//"),
            for_machine = ("for " + cfg.machine) if cfg.machine else "",
            runfiles_init = runfiles_init,
            qemu_runner = rlpath(ctx.attr.qemu_runner),
            arm_none_eabi_gdb = rlpath(ctx.attr._arm_none_eabi_gdb),
        ),
        is_executable = True,
    )

    return [
        DefaultInfo(
            executable = out,
            runfiles = ctx.runfiles(
                transitive_files = depset(transitive = [
                    ctx.attr.qemu_runner.files,
                    ctx.attr._arm_none_eabi_gdb.files,
                    ctx.attr._runfiles.files,
                ]),
            ).merge_all([
                ctx.attr.qemu_runner[DefaultInfo].default_runfiles,
                ctx.attr._arm_none_eabi_gdb[DefaultInfo].default_runfiles,
            ]),
        ),
        RunEnvironmentInfo(
            environment = ctx.attr.env,
            inherited_environment = [],
        ),
    ]

gdb_qemu_runner = rule(
    implementation = _impl,
    attrs = {
        "extra_args": attr.string_list(
            default = [],
            doc = "Extra arguments to pass to GDB",
        ),
        "enable_default_args": attr.bool(
            default = True,
            doc = "Enable default arguments passed to GDB",
        ),
        "env": attr.string_dict(
            doc = "Environment variables set when running GDB and QEMU",
        ),
        "qemu_runner": attr.label(
            default = "//rules:qemu_gdb_runner",
            executable = True,
            cfg = "exec",
        ),
        "_arm_none_eabi_gdb": attr.label(
            default = "@arm_none_eabi//:gdb",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_machine": attr.label(
            default = "//config:machine",
        ),
        "_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
    },
    executable = True,
    provides = [DefaultInfo, RunEnvironmentInfo],
    doc = (
        "Runner that starts QEMU in the background and connects GDB to it."
    ),
)
