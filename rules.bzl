load("@rules_cc//cc:defs.bzl", "cc_binary")

def stm32_binary(
        name,
        linker_scripts = [],
        linkopts = [],
        additional_linker_inputs = [],
        target_compatible_with = [],
        **kwargs):
    linker_scripts = linker_scripts or [
        "@stm32//boards:memory_region",
        "@arm_none_eabi//share:gcc_arm_linker_script",
    ]

    cc_binary(
        name = name,
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
