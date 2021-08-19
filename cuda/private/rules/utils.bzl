load("//cuda:providers.bzl", "CudaInfo")

def is_dynamic_input(src):
    return src.extension in ["so", "dll", "dylib"]

def is_object_file(src):
    return src.extension in ["obj", "o"]

def is_static_input(src):
    return src.extension in ["a", "lib", "lo"]

def is_source_file(src):
    return src.extension in ["c", "cc", "cpp", "cxx", "c++", "C", "cu"]

def is_header_file(src):
    return src.extension in ["h", "hh", "hpp", "hxx", "inc", "inl", "H", "cuh"]

def _process_srcs(srcs, source_files, header_files, object_files, static_inputs, dynamic_inputs):
    for src in srcs:
        if is_source_file(src):
            source_files.append(src)
        if is_header_file(src):
            header_files.append(src)
        if is_static_input(src):
            static_inputs.append(src)
        if is_dynamic_input(src):
            dynamic_inputs.append(src)
        if is_object_file(src):
            object_files.append(src)

def _resolve_include_prefixes(
    ctx,
    rule_kind,
    input_private_header_files,
    output_private_header_files,
    input_public_header_files,
    output_public_header_files,
    strip_include_prefix,
    include_prefix,
    local_include_paths,
    include_paths,
):
    if strip_include_prefix == "" and include_prefix == "":
        # Private headers
        for header_file in input_private_header_files:
            output_private_header_files.append(header_file)
        # Public headers
        for header_file in input_public_header_files:
            output_public_header_files.append(header_file)
        # Public include path
        if input_public_header_files:
            include_paths.append(ctx.build_file_path.replace('/BUILD.bazel', ''))
        return

    if strip_include_prefix != "":
        strip_include_prefix = strip_include_prefix[1:] if strip_include_prefix[0] == "/" else strip_include_prefix
        strip_include_prefix = strip_include_prefix[:-1] if strip_include_prefix[-1] == "/" else strip_include_prefix
    strip_path = ctx.build_file_path.replace('BUILD.bazel', strip_include_prefix)

    if include_prefix != "":
        include_prefix = include_prefix[1:] if include_prefix[0] == "/" else include_prefix
        include_prefix = include_prefix[:-1] if include_prefix[-1] == "/" else include_prefix
    add_path = "_virtual_includes/{}/{}".format(ctx.attr.name, include_prefix)

    # Calculate new include path
    include_path = ctx.bin_dir.path + "/" + ctx.build_file_path.replace('BUILD.bazel', add_path)
    # Add include path to private includes
    local_include_paths.append(include_path)
    # Add include path to public includes
    if input_public_header_files:
        include_paths.append(include_path)

    # Private headers
    for header_file in input_private_header_files:
        if strip_path not in header_file.path:
            fail("in {} rule {}: header {} is not under the specified strip prefix {}".format(
                rule_kind, ctx.label, header_file.path, strip_path
            ))
        new_header_file = ctx.actions.declare_file(header_file.path.replace(strip_path, add_path))
        ctx.actions.symlink(
            output = new_header_file,
            target_file = header_file,
        )
        output_private_header_files.append(new_header_file)

    # Public headers
    for header_file in input_public_header_files:
        if strip_path not in header_file.path:
            fail("in {} rule {}: header {} is not under the specified strip prefix {}".format(
                ctx.rule.kind, ctx.label, header_file.path, strip_path
            ))
        new_header_file = ctx.actions.declare_file(header_file.path.replace(strip_path, add_path))
        ctx.actions.symlink(
            output = new_header_file,
            target_file = header_file,
        )
        output_public_header_files.append(new_header_file)

def _process_deps(
    deps,
    object_files,
    static_inputs,
    dynamic_inputs,
    private_header_files,
    local_include_paths,
    local_quote_include_paths,
    local_system_include_paths,
    local_defines,
):
    for dep in deps:
        if CcInfo in dep:
            ctx = dep[CcInfo].compilation_context
            private_header_files.extend(
                ctx.direct_public_headers +
                ctx.direct_textual_headers +
                ctx.headers.to_list()
            )
            local_include_paths.extend(ctx.includes.to_list())
            local_quote_include_paths.extend(ctx.quote_includes.to_list())
            local_system_include_paths.extend(ctx.system_includes.to_list())
            local_defines.extend(ctx.defines.to_list())
        if CudaInfo in dep:
            object_files.extend(dep[CudaInfo].linking_context.object_files)
            static_inputs.extend(dep[CudaInfo].linking_context.static_libraries)
            dynamic_inputs.extend(dep[CudaInfo].linking_context.dynamic_libraries)

def preprocess_inputs(ctx, rule_kind):
    source_files = []
    private_header_files = []
    public_header_files = []
    object_files = []
    static_inputs = []
    dynamic_inputs = []
    # Include paths
    local_include_paths = []
    local_quote_include_paths = [
        ".",
        ctx.bin_dir.path,
    ]
    local_system_include_paths = []
    include_paths = []
    quote_include_paths = []
    system_include_paths = list(ctx.attr.includes)
    # Defines
    local_defines = list(ctx.attr.local_defines)
    defines = list(ctx.attr.defines)

    # Extract different types of inputs from srcs
    private_header_files_tmp = []
    _process_srcs(
        ctx.files.srcs,
        source_files,
        private_header_files_tmp,
        object_files,
        static_inputs,
        dynamic_inputs
    )
    # Resolve source header paths
    _resolve_include_prefixes(
        ctx,
        rule_kind,
        private_header_files_tmp,
        private_header_files,
        ctx.files.hdrs,
        public_header_files,
        ctx.attr.strip_include_prefix,
        ctx.attr.include_prefix,
        local_include_paths,
        include_paths,
    )
    # Resolve compile depenedecies
    _process_deps(
        ctx.attr.deps,
        object_files,
        static_inputs,
        dynamic_inputs,
        private_header_files,
        local_include_paths,
        local_quote_include_paths,
        local_system_include_paths,
        local_defines,
    )

    return struct(
        source_files = source_files,
        private_header_files = private_header_files,
        public_header_files = public_header_files,
        object_files = object_files,
        static_inputs = static_inputs,
        dynamic_inputs = dynamic_inputs,
        local_include_paths = local_include_paths,
        local_quote_include_paths = local_quote_include_paths,
        local_system_include_paths = local_system_include_paths,
        include_paths = include_paths,
        quote_include_paths = quote_include_paths,
        system_include_paths = system_include_paths,
        local_defines = local_defines,
        defines = defines,
    )

def process_features(features):
    requested_features = []
    unsupported_features = []
    for feature in features:
        if feature[0] == '-':
            unsupported_features.append(feature[1:])
        else:
            requested_features.append(feature)
    return struct(
        requested_features = requested_features,
        unsupported_features = unsupported_features,
    )

def combine_env(ctx, host_env, device_env):
    host_path = host_env.get("PATH", "").split(ctx.configuration.host_path_separator)
    host_ld_library_path = host_env.get("LD_LIBRARY_PATH", "").split(ctx.configuration.host_path_separator)
    device_path = host_env.get("PATH", "").split(ctx.configuration.host_path_separator)
    device_ld_library_path = host_env.get("LD_LIBRARY_PATH", "").split(ctx.configuration.host_path_separator)

    update_values = dict(device_env)
    env = dict(host_env)

    if host_path or device_path:
        path = host_path
        for value in device_path:
            if value not in path:
                path.append(value)
        update_values["PATH"] = ctx.configuration.host_path_separator.join(path)

    if host_ld_library_path or device_ld_library_path:
        ld_library_path = host_ld_library_path
        for value in device_ld_library_path:
            if value not in ld_library_path:
                ld_library_path.append(value)
        update_values["LD_LIBRARY_PATH"] = ctx.configuration.host_path_separator.join(ld_library_path)

    env.update(update_values)

    return env

def expand_make_variables(ctx, value):
    for key, value in ctx.var.items():
        value = value.replace('$({})'.format(key), value)
    return value
