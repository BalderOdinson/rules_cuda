# CUDA Bazel rules

## Contents
- [Introduction](#introduction)
- [Toolchain](https://github.com/BalderOdinson/rules_cuda/blob/main/docs/toolchain/README.md)
- [Rules](https://github.com/BalderOdinson/rules_cuda/blob/main/docs/rules/README.md)
- [Current limitations](#current-limitations)

## Introduction

This repository contains rules and toolchain for building CUDA application. It provides similar structure as [rules_cc](https://github.com/bazelbuild/rules_cc) so it should be familiar for use to anybody that used rules_cc before.

There are some implementation of building CUDA applications with Bazel but mostly they are based on providing cc_toolchain that uses nvcc as a C/C++ compiler. This differs from those kind of implementations by providing custom CUDA toolchain and using cc_toolchain as a host compiler for easier switching between compilers and possibility to have both CUDA and C/C++ rules separated.

To include CUDA rules add this to your WORKSAPCE:
```python
http_archive(
    name = "rules_cuda",
    sha256 = "80c210afb4eb9b7c6b7f1b207f15bcb93d06e8d9ae6daf70b807c799904f39f0",
    urls = ["https://github.com/BalderOdinson/rules_cuda/releases/download/0.0.2/rules_cuda-v0.0.2.tar.gz"],
)
```

To use auto configured local toolchain that comes with this package add following to WORKSPACE:
```python
load("@rules_cuda//cuda:repository.bzl", "cuda_toolchain")

cuda_toolchain()
```
This will look for CUDA path in BAZEL_CUDA_PATH env if set. Otherwise it will look CUDA_PATH on Windows and nvcc location if nvcc is in PATH on Linux. You can find out more about toolchain in following chapter.

## Toolchain

Read about CUDA toolchain on following [link](https://github.com/BalderOdinson/rules_cuda/blob/main/docs/toolchain/README.md).

## Rules

Read about CUDA rules on following [link](https://github.com/BalderOdinson/rules_cuda/blob/main/docs/rules/README.md).

## Current limitations

### Local toolchain

Supported platforms for local auto-configured toolchain:
- Windows x86-64
- Linux x86-64

### Toolchain features

Currently env is provided through config and _env_sets_ from _feature_ is ignored.

Properties _expand_if_equal_, _expand_if_false_, _expand_if_true_ from _flag_group_ and nested _flag_groups_ inside _flag_group_ are currently ignored.

### Rules

Currently only _cuda_library_ exists but _cuda_binary_ and _cuda_test_ are soon to come.

Whitespace between named arguments (ex. -isystem /usr/include) for host compiler is not handled correctly so they should be passed together if possible (ex. -isystem=/usr/include).

### Error reporting

Currently there is no type checking so error reporting is not "pretty" in that case.

### Header inclusion checking

Currently it is not checked if included headers are added to the srcs or hdrs attributes. On Windows /showIncludes prints to the console which fills the console with unnecessary information.
