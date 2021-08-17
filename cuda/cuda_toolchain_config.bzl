load("//cuda:action_names.bzl", "CUDA_ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "with_feature_set",
)
load("//cuda:providers.bzl", "CudaToolchainConfigInfo")

def create_cuda_toolchain_config(
    tools,
    features = [],
    env = {},
    use_default_shell_env = False,
):
    """
    Creates a CudaToolchainConfigInfo provider

    Args:
        tools: All files required to build cuda code (usually everything inside cuda folder)
        features: A list of features
        env: Sets the dictionary of environment variables.
        use_default_shell_env: Whether the toolchain should use the built in shell environment or not.

    Returns:
        CudaToolchainConfigInfo
    """
    default_feature_names = [
        "dbg", "fastbuild", "opt",
        "default_compile_flags", "default_warning_flags",
        "gpu_architecture_flag", "gpu_code_flags",
        "maximum_register_count", "use_fast_math",
        "default_host_compiler_flags", "forward_unknown_args_to_host_compiler",
        "allow_unsupported_compiler", "compile_device_code_flag", "include_paths",
        "compiler_input_flags", "compiler_output_flags",
        "includes", "library_search_directories", "libraries_to_link",
        "link_device_code_flag", "linker_output_flags",
    ]

    default_features = {
        "dbg": feature(name = "dbg"),
        "fastbuild": feature(name = "fastbuild"),
        "opt": feature(name = "opt"),
        "default_compile_flags": feature(
            name = "default_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-G"])],
                    with_features = [with_feature_set(features = ["dbg"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-Xptxas", "-O3"])],
                    with_features = [with_feature_set(features = ["opt"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-use_fast_math"])],
                    with_features = [with_feature_set(features = ["use_fast_math"], not_features = ["dbg"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-ftz"])],
                    with_features = [with_feature_set(features = ["use_ftz"], not_features = ["dbg"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-prec-div=false"])],
                    with_features = [with_feature_set(features = ["use_fast_div"], not_features = ["dbg"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-prec-sqrt=false"])],
                    with_features = [with_feature_set(features = ["use_fast_sqrt"], not_features = ["dbg"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-fmad=true"])],
                    with_features = [with_feature_set(features = ["use_fmad"], not_features = ["dbg"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [flag_group(flags = ["-extra-device-vectorization"])],
                    with_features = [with_feature_set(features = ["extra_device_vectorization"], not_features = ["dbg"])],
                ),
            ],
        ),
        "default_warning_flags": feature(
            name = "default_warning_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-Wreorder",
                                "-Wdefault-stream-launch",
                                "-Wext-lambda-captures-this",
                                "-Xptxas", "-warn-double-usage",
                                "-Xptxas", "-warn-lmem-usage",
                            ],
                        ),
                    ],
                ),
            ],
        ),
        "gpu_architecture_flag": feature(
            name = "gpu_architecture_flag",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-arch", "%{gpu_arch}"],
                            expand_if_available = "gpu_arch",
                        ),
                    ],
                ),
            ],
        ),
        "gpu_code_flags": feature(
            name = "gpu_code_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-code", "%{gpu_codes}"],
                            expand_if_available = "gpu_arch",
                            iterate_over = "gpu_codes",
                        ),
                    ],
                ),
            ],
        ),
        "maximum_register_count": feature(
            name = "maximum_register_count",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-maxrregcount", "%{max_reg_count}"],
                            expand_if_available = "max_reg_count",
                        ),
                    ],
                ),
            ],
        ),
        "use_fast_math": feature(name = "use_fast_math", implies = ["use_ftz", "use_fast_div", "use_fast_sqrt", "use_fmad"]),
        "use_ftz": feature(name = "use_ftz"),
        "use_fast_div": feature(name = "use_fast_div"),
        "use_fast_sqrt": feature(name = "use_fast_sqrt"),
        "use_fmad": feature(name = "use_fmad"),
        "extra_device_vectorization": feature(name = "extra_device_vectorization"),
        "default_host_compiler_flags": feature(
            name = "default_host_compiler_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile, CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-forward-unknown-to-host-compiler"
                            ],
                        ),
                    ],
                    with_features = [with_feature_set(features = ["forward_unknown_args_to_host_compiler"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile, CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-allow-unsupported-compiler"
                            ],
                        ),
                    ],
                    with_features = [with_feature_set(features = ["allow_unsupported_compiler"])],
                ),
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile, CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-ccbin", "%{host_compiler_executable}"
                            ],
                            expand_if_available = "host_compiler_executable",
                        ),
                        flag_group(
                            flags = [
                                "-Xcompiler", "%{host_compiler_arguments}"
                            ],
                            iterate_over = "host_compiler_arguments",
                        ),
                    ],
                ),
            ],
        ),
        "forward_unknown_args_to_host_compiler": feature(name = "forward_unknown_args_to_host_compiler"),
        "allow_unsupported_compiler": feature(name = "allow_unsupported_compiler"),
        "compile_device_code_flag": feature(
            name = "compile_device_code_flag",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-dc"],
                        ),
                    ],
                ),
            ],
        ),
        "link_device_code_flag": feature(
            name = "link_device_code_flag",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            flags = ["-dlink"],
                        ),
                    ],
                ),
            ],
        ),
        "include_paths": feature(
            name = "include_paths",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-I%{include_paths}"],
                            iterate_over = "include_paths",
                        ),
                        flag_group(
                            flags = ["-isystem%{system_include_paths}"],
                            iterate_over = "system_include_paths",
                        ),
                    ],
                ),
            ],
        ),
        "compiler_input_flags": feature(
            name = "compiler_input_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            expand_if_available = "source_file",
                            flags = ["%{source_file}"],
                        ),
                    ],
                ),
            ],
        ),
        "compiler_output_flags": feature(
            name = "compiler_output_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            expand_if_available = "output_file",
                            flags = ["-o", "%{output_file}"],
                        ),
                    ],
                ),
            ],
        ),
        "includes":  feature(
            name = "includes",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-include", "%{includes}"],
                            iterate_over = "includes",
                        ),
                    ],
                ),
            ],
        ),
        "library_search_directories": feature(
            name = "library_search_directories",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            flags = ["-L", "%{library_search_directories}"],
                            iterate_over = "library_search_directories",
                        ),
                    ],
                ),
            ],
        ),
        "libraries_to_link": feature(
            name = "libraries_to_link",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            flags = ["%{static_libraries}"],
                            iterate_over = "static_libraries",
                        ),
                        flag_group(
                            flags = ["-l%{shared_libraries}"],
                            iterate_over = "shared_libraries",
                        ),
                        flag_group(
                            flags = ["%{objects}"],
                            iterate_over = "objects",
                        ),
                    ],
                ),
            ],
        ),
        "linker_output_flags": feature(
            name = "linker_output_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [CUDA_ACTION_NAMES.link],
                    flag_groups = [
                        flag_group(
                            expand_if_available = "output_file",
                            flags = ["-o", "%{output_file}"],
                        ),
                    ],
                ),
            ],
        ),
    }

    merged_features = {}

    for _feature in features:
        if _feature.name in default_feature_names:
            default_feature_names.remove(_feature.name)
        merged_features[_feature.name] = _feature

    for feature_name in default_feature_names:
        merged_features[feature_name] = default_features[feature_name]

    return CudaToolchainConfigInfo(
        tools = tools,
        env = env,
        use_default_shell_env = use_default_shell_env,
        features = merged_features,
    )
