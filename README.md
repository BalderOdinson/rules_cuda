# CUDA rules for Bazel

rules_cuda aims to provide rules for building CUDA applications that are similar and compatible with rules_cc.
It comes with custom toolchain to support different host compilers (current cc_toolchain will be used as host compiler).
Local auto-configured CUDA toolchain comes with rules_cuda but custom toolchain can be provided similarly how custom cc toolchain is provided.
Read more in the docs section.

## Quickstart

Add this to your WORKSPACE to include rules_cuda.

```python
http_archive(
    name = "rules_cuda",
    sha256 = "3f320d3cded754891e5e2aa55fe3305eef0a2eabac8bffd117923ca190b6a302",
    urls = ["https://github.com/BalderOdinson/rules_cuda/releases/download/0.0.3/rules_cuda-v0.0.3.tar.gz"],
)

# Add lines below to use local CUDA toolchain.
load("@rules_cuda//cuda:repository.bzl", "cuda_toolchain")
cuda_toolchain()
```
## Documentation

Documentation on how to use rules_cuda: [link](https://github.com/BalderOdinson/rules_cuda/blob/main/docs/README.md)

## Examples

Examples are available inside this repository in folder [examples](https://github.com/BalderOdinson/rules_cuda/tree/main/examples).

*Note - to run an example you must be positioned inside examples directory.*

## Contributions

All contributions are welcome :)
