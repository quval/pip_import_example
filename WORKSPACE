load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_python",
    sha256 = "5868e73107a8e85d8f323806e60cad7283f34b32163ea6ff1020cf27abef6036",
    strip_prefix = "rules_python-0.25.0",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.25.0.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

python_register_toolchains(
    name = "python_toolchains",
    ignore_root_user_error = True,
    python_version = "3.10.8",
)

load("//rules/pip:pip.bzl", "pip_repositories")

pip_repositories()

load("//rules:remote_assets.bzl", "remote_assets")

remote_assets(
    name = "pypi",
    spec = "//third_party/pip:pypi.json",
)

load("@pypi//:repositories.bzl", configure_pypi = "configure_assets")

configure_pypi()
