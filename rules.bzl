load("@rules_cc//cc:defs.bzl", "cc_binary")

def stm32_binary(
        name,
        semihosting = False,
        startup_srcs = [],
        srcs = [],
        deps = [],
        linker_scripts = [],
        linkopts = [],
        additional_linker_inputs = [],
        target_compatible_with = [],
        **kwargs):
    linker_scripts = linker_scripts or [
        "@stm32//boards:memory_region",
        "@arm_none_eabi//share:gcc_arm_linker_script",
    ]

    if not startup_srcs:
        deps = deps + ["@stm32//src/startup{}".format(":semihosting" if semihosting else "")]

    cc_binary(
        name = name,
        srcs = srcs + startup_srcs,
        deps = deps,
        linkopts = linkopts + [
            "-T$(rootpath {})".format(ls)
            for ls in linker_scripts
        ],
        additional_linker_inputs = additional_linker_inputs + linker_scripts,
        target_compatible_with = target_compatible_with + [
            "@platforms//os:none",
            "@stm32//constraints:cpu",
        ],
        **kwargs
    )

    native.genrule(
        name = name + "_map",
        srcs = [name],
        outs = [name + ".map"],
        tools = ["@arm_none_eabi//:objdump"],
        cmd = "$(location @arm_none_eabi//:objdump) -C --all-headers $< > $@",
    )
