# CUDA rules for Bazel

rules_cuda aims to provide rules for building CUDA applications that are similar and compatible with rules_cc.
It comes with custom toolchain to support different host compilers (current cc_toolchain will be used as host compiler).
Local auto-configured CUDA toolchain comes with rules_cuda but custom toolchain can be provided similarly how custom cc toolchain is provided.
Read more in the docs section.

## Quickstart

Add this to your WORKSPACE to include rules_cuda.

```
http_archive(
    name = "rules_cuda",
    sha256 = "<sha>",
    urls = ["<url>"],
)

# Add lines below to use local CUDA toolchain.
load("@rules_cuda//cuda:repository.bzl", "cuda_toolchain")
cuda_toolchain()
```
## Documentation

Documentation on how to use rules_cuda: <url>

## Contributions

All contributions are welcome :)
