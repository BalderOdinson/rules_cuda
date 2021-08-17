load("@rules_cuda//cuda:cuda_toolchain_config.bzl", "create_cuda_toolchain_config")

def _impl(ctx):
    return create_cuda_toolchain_config(
        tools = ctx.files.tools,
        use_default_shell_env = True,
    )

cuda_toolchain_config = rule(
    attrs = {
        "tools": attr.label_list(
            mandatory = True,
            allow_files = True,
        )
    },
    implementation = _impl,
)
