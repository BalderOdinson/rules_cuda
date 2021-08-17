load("//cuda:private/toolchain/cuda_configure.bzl", "cuda_configure")

def cuda_toolchain(name = "cuda_toolchain"):
    cuda_configure(name = "local_cuda_config")
    native.register_toolchains(
        "@local_cuda_config//:local_toolchain",
    )
