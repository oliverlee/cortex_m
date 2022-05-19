load("@rules_cc//cc:defs.bzl", "cc_binary")

def stm32_qemu_test(
        name,
        deps = [],
        **kwargs):
    native.sh_test(
        name = name,
        srcs = ["test_{}.sh".format(name)],
        data = [
            "@stm32//tools/qemu:semihosting",
            ":test_{}".format(name),
        ],
    )

    native.genrule(
        name = "gentest_{}".format(name),
        outs = ["test_{}.sh".format(name)],
        srcs = [
            "@stm32//tools/qemu:semihosting",
            ":test_{}".format(name),
        ],
        cmd = ("echo $(rootpath @stm32//tools/qemu:semihosting) " +
               "$(rootpath :test_{}) > $@".format(name)),
    )

    stm32_binary(
        name = "test_{}".format(name),
        startup = "semihosting",
        deps = deps + ["@ut", "@stm32//src/test:cfg"],
        **kwargs
    )

def stm32_binary(
        name,
        startup = "startup",
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

    if startup:
        deps = deps + ["@stm32//src/startup:{}".format(startup)]

    native.alias(
        name = name,
        actual = ":{}.elf".format(name),
    )

    cc_binary(
        name = "{}.elf".format(name),
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
