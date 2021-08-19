# CUDA toolchain

## Contents
- [Introduction](#introduction)
- [create_cuda_toolchain_config](#create_cuda_toolchain_config)
- [cuda_toolchain](#cuda_toolchain)
- [Default features](#default-features)

## Introduction

Repository rules_cuda comes with custom toolchain (type - _@rules_cuda//cuda:toolchain_type_). It is configured similarly as _cc_toolchain_.

## create_cuda_toolchain_config

_CudaToolchainConfigInfo_ provider contains required config for creating the toolchain. _create_cuda_toolchain_config_ is function that creates the provider.

### Parameters
| Parameter             | Description                                                                                  |
|:----------------------|:---------------------------------------------------------------------------------------------|
| tools                 | default = [] <br/> A list of [tool_paths](https://github.com/bazelbuild/bazel/blob/master/tools/cpp/cc_toolchain_config_lib.bzl#L400). |
| features              | default = [] <br/> A list of [features](https://github.com/bazelbuild/bazel/blob/master/tools/cpp/cc_toolchain_config_lib.bzl#L336). Default features can be found [here](#default-features). |
| env                   | [dict](https://docs.bazel.build/versions/main/skylark/lib/dict.html); default = {} <br/> Sets the dictionary of environment variables. Combined with env returned by cc_toolchain. |
| use_default_shell_env | default = False <br/> Whether the toolchain should use the built in shell environment or not (in case of True env parameter and env provided by cc_toolchain will be ignored). |

### Example

```python
load(
    "@rules_cuda//cuda:cuda_toolchain_config.bzl",
    "create_cuda_toolchain_config",
)
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
    "feature",
)

create_cuda_toolchain_config(
    tools = [
        tool_path(
            name = "nvcc",
            path = ctx.file.nvcc.path,
        ),
    ],
    features = [
        feature(name = "example_feature"),
    ],
    use_default_shell_env = True,
)
```


## cuda_toolchain

Rule that provides _CudaToolchainInfo_ required for building CUDA targets.

### Parameters

| Parameter | Description                                                                                  |
|:----------|:---------------------------------------------------------------------------------------------|
| config    | [Label](https://docs.bazel.build/versions/main/skylark/lib/Label.html); required <br/> Label of Target that provides CudaToolchainConfigInfo.             |
| all_files | [sequence](https://docs.bazel.build/versions/main/skylark/lib/list.html) of [File](https://docs.bazel.build/versions/main/skylark/lib/File.html); default = [] <br/> Collection of all cuda_toolchain artifacts. These artifacts will be added as inputs to all rules_cuda related actions. |
| libraries | [sequence](https://docs.bazel.build/versions/main/skylark/lib/list.html) of [File](https://docs.bazel.build/versions/main/skylark/lib/File.html); default = [] <br/> List of all libs (static or shared) to be linked with C/C++ code. For example CUDA Runtime library is required to be able to link CUDA with C/C++. |

### Example

```python
load("@rules_cuda//cuda:defs.bzl", "cuda_toolchain")

filegroup(
    name ="all_files",
    srcs = glob([
        "cuda/bin/**",
        "cuda/include/**",
        "cuda/lib64/**",
        "cuda/nvvm/**",
    ]),
)

cuda_toolchain(
    name = "cuda_toolchain",
    config = ":cuda_config",
    libraries = [
        ":libcudart",
    ],
    all_files = [
        ":all_files",
    ],
)

toolchain(
    name = "toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":cuda_toolchain",
    toolchain_type = "@rules_cuda//cuda:toolchain_type",
)
```

## Default features

This are the default features that will be used if not provided through feature parameter in [create_cuda_toolchain_config](#create_cuda_toolchain_config).

| Name                                  | Actions       | Enabled                     | Variables used                                    |
|:--------------------------------------|:--------------|:----------------------------|:--------------------------------------------------|
| dbg                                   | N/A           | Depends on compilation mode | N/A                                               |
| fastbuild                             | N/A           | Depends on compilation mode | N/A                                               |
| opt                                   | N/A           | Depends on compilation mode | N/A                                               |
| default_compile_flags                 | compile       | True                        | N/A                                               |
| default_warning_flags                 | compile       | True                        | N/A                                               |
| gpu_architecture_flag                 | compile       | True                        | gpu_arch                                          |
| gpu_code_flags                        | compile       | True                        | gpu_codes                                         |
| maximum_register_count                | compile       | True                        | max_reg_count                                     |
| use_fast_math                         | compile       | False                       | N/A                                               |
| use_ftz                               | compile       | False                       | N/A                                               |
| use_fast_div                          | compile       | False                       | N/A                                               |
| use_fast_sqrt                         | compile       | False                       | N/A                                               |
| use_fmad                              | compile       | False                       | N/A                                               |
| extra_device_vectorization            | compile       | False                       | N/A                                               |
| default_host_compiler_flags           | compile, link | True                        | host_compiler_executable, host_compiler_arguments |
| forward_unknown_args_to_host_compiler | compile       | False                       | N/A                                               |
| allow_unsupported_compiler            | compile       | False                       | N/A                                               |
| compile_device_code_flag              | compile       | True                        | N/A                                               |
| link_device_code_flag                 | link          | True                        | N/A                                               |
| include_paths                         | compile       | True                        | include_paths, system_include_paths               |
| compiler_input_flags                  | compile       | True                        | source_file                                       |
| compiler_output_flags                 | compile       | True                        | output_file                                       |
| includes                              | compile       | True                        | includes                                          |
| library_search_directories            | link          | True                        | library_search_directories                        |
| libraries_to_link                     | link          | True                        | static_libraries, shared_libraries, objects       |
| linker_output_flags                   | link          | True                        | output_file                                       |

