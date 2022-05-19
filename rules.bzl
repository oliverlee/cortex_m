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

    native.alias(
        name = name,
        actual = ":{}.elf".format(name),
    )

    cc_binary(
        name = "{}.elf".format(name),
        srcs = srcs + startup_srcs,
        deps = deps,
        linkopts = linkopts + [
            "-T$(rootpath {})".format(ls)
            for ls in linker_scripts
        ] + [
            "-Wl,-Map={}.map,--cref".format(
                name,
            ),
        ],
        additional_linker_inputs = additional_linker_inputs + linker_scripts,
        target_compatible_with = target_compatible_with + [
            "@platforms//os:none",
            "@stm32//constraints:cpu",
        ],
        **kwargs
    )

    native.genrule(
        name = "{}_lss".format(name),
        srcs = ["{}.elf".format(name)],
        outs = ["{}.lss".format(name)],
        tools = ["@arm_none_eabi//:objdump"],
        cmd = "$(execpath @arm_none_eabi//:objdump) --source --line-numbers --demangle $< > $@",
    )

    native.genrule(
        name = "{}_dmp".format(name),
        srcs = ["{}.elf".format(name)],
        outs = ["{}.dmp".format(name)],
        tools = ["@arm_none_eabi//:objdump"],
        cmd = "$(execpath @arm_none_eabi//:objdump) --all-headers --syms --demangle $< > $@",
    )
