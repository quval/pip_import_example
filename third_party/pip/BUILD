load("//rules/pip:pip.bzl", "pip_import")

pip_import(
    name = "asttokens",
    path = "@pypi//:asttokens-2.0.8-py2.py3-none-any.whl",
    deps = [":six"],
)

pip_import(
    name = "backcall",
    path = "@pypi//:backcall-0.2.0-py2.py3-none-any.whl",
)

pip_import(
    name = "decorator",
    path = "@pypi//:decorator-5.1.1-py3-none-any.whl",
    visibility = ["//visibility:public"],
)

pip_import(
    name = "executing",
    path = "@pypi//:executing-1.0.0-py2.py3-none-any.whl",
)

pip_import(
    name = "ipython",
    actual_import = "IPython",
    path = "@pypi//:ipython-8.5.0-py3-none-any.whl",
    visibility = ["//visibility:public"],
    deps = [
        ":backcall",
        ":decorator",
        ":jedi",
        ":matplotlib_inline",
        ":pexpect",
        ":pickleshare",
        ":prompt_toolkit",
        ":pygments",
        ":stack_data",
        ":traitlets",
    ],
)

pip_import(
    name = "jedi",
    path = "@pypi//:jedi-0.18.1-py2.py3-none-any.whl",
    deps = [":parso"],
)

pip_import(
    name = "matplotlib_inline",
    path = "@pypi//:matplotlib_inline-0.1.6-py3-none-any.whl",
    deps = [":traitlets"],
)

pip_import(
    name = "parso",
    path = "@pypi//:parso-0.8.3-py2.py3-none-any.whl",
)

pip_import(
    name = "pexpect",
    path = "@pypi//:pexpect-4.8.0-py2.py3-none-any.whl",
    deps = [":ptyprocess"],
)

pip_import(
    name = "pickleshare",
    path = "@pypi//:pickleshare-0.7.5-py2.py3-none-any.whl",
)

pip_import(
    name = "prompt_toolkit",
    path = "@pypi//:prompt_toolkit-3.0.31-py3-none-any.whl",
    visibility = ["//visibility:public"],
    deps = [":wcwidth"],
)

pip_import(
    name = "ptyprocess",
    path = "@pypi//:ptyprocess-0.7.0-py2.py3-none-any.whl",
)

pip_import(
    name = "pure_eval",
    path = "@pypi//:pure_eval-0.2.2-py3-none-any.whl",
)

pip_import(
    name = "pygments",
    path = "@pypi//:Pygments-2.13.0-py3-none-any.whl",
)

pip_import(
    name = "six",
    path = "@pypi//:six-1.16.0-py2.py3-none-any.whl",
)

pip_import(
    name = "stack_data",
    path = "@pypi//:stack_data-0.5.0-py3-none-any.whl",
    deps = [
        ":asttokens",
        ":executing",
        ":pure_eval",
    ],
)

pip_import(
    name = "traitlets",
    path = "@pypi//:traitlets-5.4.0-py3-none-any.whl",
)

pip_import(
    name = "wcwidth",
    path = "@pypi//:wcwidth-0.2.5-py2.py3-none-any.whl",
)
