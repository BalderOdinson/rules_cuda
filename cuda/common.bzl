def _configure_features(
    ctx,
    cuda_toolchain,
    requested_features=[],
    unsupported_features=[]
):
    features = cuda_toolchain.features
    enabled_features = {}

    # Enable compilation mode feature
    compilation_mode = ctx.var["COMPILATION_MODE"]
    if compilation_mode in features:
        enabled_features[compilation_mode] = features[compilation_mode]

    # Find all user enabled features
    for feature_name, _feature in features.items():
        if _feature.enabled and feature_name not in unsupported_features:
            enabled_features[feature_name] = _feature
        elif _feature.name in requested_features:
            enabled_features[feature_name] = _feature

    # Find all implied features
    for feature_name, _feature in enabled_features.items():
        for implied_feature_name in _feature.implies:
            if implied_feature_name not in enabled_features:
                if implied_feature_name in unsupported_features:
                    fail("{} feature is implied by {} but it is explicitly disabled!".format(implied_feature_name, feature_name))
                if implied_feature_name not in features:
                    fail("{} feature is implied by {} but it was not provided!".format(implied_feature_name, feature_name))
                enabled_features[implied_feature_name] = features[implied_feature_name]

    # Check provided features
    unique_providers = {}
    for feature_name, _feature in enabled_features.items():
        for provided_feature_name in _feature.provides:
            if provided_feature_name in unique_providers:
                fail("{} and {} provides same feature: {}!".format(unique_providers[provided_feature_name], feature_name, provided_feature_name))
            unique_providers[provided_feature_name] = feature_name

    # Check required features
    for feature_name, _feature in enabled_features.items():
        feature_set_found = True
        for required_feature_set in _feature.requires:
            for required_feature_name in required_feature_set.features:
                if required_feature_name not in enabled_features:
                    feature_set_found = False
                    break
            if feature_set_found:
                for required_feature_name in required_feature_set.not_features:
                    if required_feature_name in enabled_features:
                        feature_set_found = False
                        break
            if feature_set_found:
                break
        if not feature_set_found:
            fail("Could not find matching required features_set for feature {}!".format(feature_name))

    return enabled_features.keys()

def _create_link_variables(
    host_compiler_executable = None,
    host_compiler_arguments = [],
    objects = [],
    static_libraries = [],
    shared_libraries = [],
    output_file = None,
):
    variables = {
        "objects": [object.path for object in objects],
        "static_libraries": [static_library.path for static_library in static_libraries],
        "shared_libraries": [shared_library.basename for shared_library in shared_libraries],
        "library_search_directories": [shared_library.dirname for shared_library in shared_libraries],
    }

    if host_compiler_executable != None:
        variables["host_compiler_executable"] = host_compiler_executable

    if host_compiler_arguments:
        variables["host_compiler_arguments"] = host_compiler_arguments

    if output_file != None:
        variables["output_file"] = output_file.path

    return variables

def _create_compile_variables(
    source_file = None,
    output_file = None,
    gpu_arch = "",
    gpu_codes = [],
    max_reg_count = 0,
    host_compiler_executable = None,
    host_compiler_arguments = [],
    include_paths = [],
    system_include_paths = [],
    includes = [],
):
    variables = {
        "gpu_codes": gpu_codes,
        "include_paths": include_paths,
        "system_include_paths": system_include_paths,
        "includes": [include.path for include in includes],
    }

    if source_file != None:
        variables["source_file"] = source_file.path

    if output_file != None:
        variables["output_file"] = output_file.path

    if gpu_arch != "":
        variables["gpu_arch"] = gpu_arch

    if max_reg_count > 0:
        variables["max_reg_count"] = str(max_reg_count)

    if host_compiler_executable != None:
        variables["host_compiler_executable"] = host_compiler_executable

    if host_compiler_arguments:
        variables["host_compiler_arguments"] = host_compiler_arguments

    return variables

def _get_nvcc_tool_path(cuda_toolchain):
    return cuda_toolchain.nvcc_path

def _get_memory_inefficient_command_line(
    cuda_toolchain,
    action_name,
    feature_configuration = [],
    variables = {},
):
    enabled_flag_sets = []

    for feature_name in feature_configuration:
        for _flag_set in cuda_toolchain.features[feature_name].flag_sets:
            # Check feature set for correct action
            if action_name not in _flag_set.actions:
                continue

            # Check feature set for required features
            feature_set_found = True
            for required_feature_set in _flag_set.with_features:
                feature_set_found = True
                for required_feature_name in required_feature_set.features:
                    if required_feature_name not in feature_configuration:
                        feature_set_found = False
                        break
                if feature_set_found:
                    for required_feature_name in required_feature_set.not_features:
                        if required_feature_name in feature_configuration:
                            feature_set_found = False
                            break
                if feature_set_found:
                    break
            if not feature_set_found:
                continue

            enabled_flag_sets.append(_flag_set)

    args = []

    for _feature_set in enabled_flag_sets:
        for _flag_group in _feature_set.flag_groups:
            if _flag_group.expand_if_available != None and _flag_group.expand_if_available not in variables:
                continue
            if _flag_group.expand_if_not_available != None and _flag_group.expand_if_not_available in variables:
                continue
            if _flag_group.iterate_over != None and _flag_group.iterate_over not in variables:
                continue

            flags = list(_flag_group.flags)
            if _flag_group.iterate_over != None:
                flags = []
                for variable in variables[_flag_group.iterate_over]:
                    for flag in _flag_group.flags:
                        flags.append(flag.replace("%{{{}}}".format(_flag_group.iterate_over), variable))

            for idx in range(len(flags)):
                for variable_name, variable in variables.items():
                    flags[idx] = flags[idx].replace("%{{{}}}".format(variable_name), ' '.join(variable) if type(variable) == type([]) else variable)

            args.extend(flags)

    return args

def _create_linking_context(
    object_files = [],
    static_libraries = [],
    dynamic_libraries = [],
):
    return struct(
        object_files = object_files,
        static_libraries = static_libraries,
        dynamic_libraries = dynamic_libraries,
    )

cuda_common = struct(
    configure_features = _configure_features,
    create_link_variables = _create_link_variables,
    create_compile_variables = _create_compile_variables,
    create_linking_context = _create_linking_context,
    get_nvcc_tool_path = _get_nvcc_tool_path,
    get_memory_inefficient_command_line = _get_memory_inefficient_command_line,
)
