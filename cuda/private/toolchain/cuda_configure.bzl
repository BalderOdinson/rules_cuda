load("//cuda:private/toolchain/cuda_configure_windows.bzl", "configure_windows_toolchain")
load("//cuda:private/toolchain/cuda_configure_linux.bzl", "configure_linux_toolchain")
load("//cuda:private/toolchain/lib_cuda_configure.bzl",
    "get_cpu_value",
    "auto_configure_fail"
)

def _cuda_configure_impl(repository_ctx):
    cpu = get_cpu_value(repository_ctx)
    if cpu == "x64_windows":
        configure_windows_toolchain(repository_ctx)
    elif cpu == "k8":
        configure_linux_toolchain(repository_ctx)
    else:
        auto_configure_fail("Unsupported platform")

cuda_configure = repository_rule(
    implementation = _cuda_configure_impl,
)
