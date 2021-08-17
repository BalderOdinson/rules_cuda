CudaToolchainConfigInfo = provider(
    doc = "Config required to build CUDA toolchain",
    fields = [
        "tools",
        "features",
        "env",
        "use_default_shell_env",
    ],
)

CudaToolchainInfo = provider(
    doc = "Information about invoking nvcc",
    fields = [
        "nvcc_path",
        "tools",
        "libraries",
        "features",
        "env",
        "use_default_shell_env",
    ],
)

CudaInfo = provider(
    doc = "Contains information for compilation and linking of cuda_library rules",
    fields = ["linking_context"]
)
