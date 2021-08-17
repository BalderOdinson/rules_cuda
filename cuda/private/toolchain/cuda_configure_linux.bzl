load("//cuda:private/toolchain/lib_cuda_configure.bzl",
    "get_env_var",
    "auto_configure_fail",
    "which",
)

def configure_linux_toolchain(repository_ctx):
    cuda_path = get_env_var(repository_ctx, "BAZEL_CUDA_PATH", False, False)
    if not cuda_path:
        cuda_path = which(repository_ctx, "nvcc")
        if cuda_path:
            cuda_path = cuda_path.replace('/bin/nvcc', '')
    if not cuda_path or not repository_ctx.path(cuda_path).exists:
        auto_configure_fail("CUDA not installed or either 'BAZEL_CUDA_PATH' variable not set or nvcc is not in PATH variable.")

    repository_ctx.symlink(cuda_path, 'cuda_tools')
    repository_ctx.symlink(Label('//cuda:private/toolchain/local_cuda_config.bzl.tpl'), 'local_cuda_config.bzl')
    substitutions = {
        "%{cuda_tools_include}": cuda_path + '/include',
    }
    repository_ctx.template(
        "BUILD.bazel",
        Label("//cuda:private/toolchain/BUILD.linux"),
        substitutions
    )
