load(
    "@rules_cuda//cuda:cuda_toolchain_config.bzl",
    "create_cuda_toolchain_config",
)
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
)

def _impl(ctx):
    return create_cuda_toolchain_config(
        tools = [
            tool_path(
                name = "nvcc",
                path = ctx.file.nvcc.path,
            ),
        ],
        use_default_shell_env = True,
    )

cuda_toolchain_config = rule(
    attrs = {
        "nvcc": attr.label(
            mandatory = True,
            allow_single_file = True,
        )
    },
    implementation = _impl,
)
