sh_binary(
    name = "pip",
    srcs = ["pip.sh"],
    data = [
        ":python_runtime",
        "@io_pypa_pip_whl//file",
        "@io_pypa_setuptools_whl//file",
        "@io_pypa_wheel_whl//file",
    ],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_binary(
    name = "pyc_compiler",
    srcs = ["pyc_compiler.sh"],
    data = [":python_runtime"],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_binary(
    name = "python_runtime",
    srcs = ["@python_toolchains_x86_64-unknown-linux-gnu//:bin/python3"],
    data = ["@python_toolchains_x86_64-unknown-linux-gnu//:files"],
)

alias(
    name = "python_headers",
    actual = "@python_toolchains_x86_64-unknown-linux-gnu//:python_headers",
    visibility = ["//visibility:public"],
)
