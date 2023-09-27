"""Rules for importing pip packages."""

load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "CPP_COMPILE_ACTION_NAME",
    "CPP_LINK_STATIC_LIBRARY_ACTION_NAME",
)
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def pip_repositories():
    maybe(
        http_archive,
        name = "dbx_build_tools",
        urls = [
            "https://github.com/dropbox/dbx_build_tools/archive/98e980756af34e8ab6edf78ca0e8b041ae2a883f.zip",
        ],
        sha256 = "1cd7c764db3f8758cb4e68a8ba2bad0aeaec4fa813c8e03260225aead97360ce",
        strip_prefix = "dbx_build_tools-98e980756af34e8ab6edf78ca0e8b041ae2a883f",
    )

    maybe(
        http_file,
        name = "io_pypa_pip_whl",
        sha256 = "0f35d63b7245205f4060efe1982f5ea2196aa6e5b26c07669adcf800e2542026",
        urls = [
            "https://files.pythonhosted.org/packages/4e/5f/528232275f6509b1fff703c9280e58951a81abe24640905de621c9f81839/pip-20.2.3-py2.py3-none-any.whl",
        ],
        downloaded_file_path = "pip-20.2.3-py2.py3-none-any.whl",
    )

    maybe(
        http_file,
        name = "io_pypa_setuptools_whl",
        sha256 = "2c242a0856fbad7efbe560df4a7add9324f340cf48df43651e9604924466794a",
        urls = [
            "https://files.pythonhosted.org/packages/6d/38/c21ef5034684ffc0412deefbb07d66678332290c14bb5269c85145fbd55e/setuptools-50.3.2-py3-none-any.whl",
        ],
        downloaded_file_path = "setuptools-50.3.2-py3-none-any.whl",
    )

    maybe(
        http_file,
        name = "io_pypa_wheel_whl",
        sha256 = "f4da1763d3becf2e2cd92a14a7c920f0f00eca30fdde9ea992c836685b9faf28",
        urls = [
            "https://files.pythonhosted.org/packages/00/83/b4a77d044e78ad1a45610eb88f745be2fd2c6d658f9798a15e384b7d57c9/wheel-0.33.6-py2.py3-none-any.whl",
        ],
        downloaded_file_path = "wheel-0.33.6-py2.py3-none-any.whl",
    )

def _cc_toolchain_info(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    return cc_toolchain, feature_configuration

ImportPipInfo = provider("Info about pip package", fields = ["wheel", "extras", "version"])

def _pip_import_impl(ctx):
    # We cannot know the execution root right now; the tool will take care of it
    # by replacing $ROOT/ with the relevant path.
    cc_toolchain, feature_configuration = _cc_toolchain_info(ctx)
    c_compiler = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_COMPILE_ACTION_NAME,
    )
    archiver = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
    )
    cc_infos = [ctx.attr._python_headers[CcInfo]]
    for dep in ctx.attr.deps:
        if CcInfo in dep:
            cc_infos.append(dep[CcInfo])
    merged_cc_info = cc_common.merge_cc_infos(cc_infos = cc_infos)

    additional_inputs = []
    ldflags = ["-pthread", "-Wl,--exclude-libs=ALL"]
    for linker_input in merged_cc_info.linking_context.linker_inputs.to_list():
        ldflags += ["-L$ROOT/" + lib.pic_static_library.dirname for lib in linker_input.libraries]
        ldflags += linker_input.user_link_flags
        additional_inputs += linker_input.additional_inputs
        additional_inputs += [lib.pic_static_library for lib in linker_input.libraries]

    # We provide runtime dependencies in build time as well.
    build_deps = depset(transitive = [
        dep[DefaultInfo].default_runfiles.files
        for dep in ctx.attr.deps
    ])
    extracted_dir = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(
        outputs = [extracted_dir],
        inputs = depset([ctx.file.path] + ctx.files.patches, transitive = [
            build_deps,
            merged_cc_info.compilation_context.headers,
            depset(additional_inputs),
        ]),
        tools = [
            ctx.executable._ldshared,
            ctx.executable._pip,
            ctx.executable._pyc_compiler,
        ],
        env = {
            "AR": archiver,
            "ARFLAGS": "Drc",
            "CC": c_compiler,
            "CFLAGS": " ".join([
                "-isystem $ROOT/" + path
                for path in merged_cc_info.compilation_context.system_includes.to_list()
            ] + [
                "-iquote $ROOT/" + path
                for path in merged_cc_info.compilation_context.quote_includes.to_list()
            ] + [
                "-ffile-prefix-map=$ROOT/=",
            ]),
            "CPLUS_INCLUDE_PATH": ":".join([
                "$ROOT/" + path
                for path in merged_cc_info.compilation_context.system_includes.to_list()
            ]),
            "CXX": "$ROOT/" + ctx.executable._ldshared.path,
            "LD": c_compiler,
            "LDFLAGS": " ".join(ldflags),
            "LDSHARED": "$ROOT/" + ctx.executable._ldshared.path,
            "PATH": "/bin:/usr/bin",
            "PYTHONPATH": ":".join([
                "$ROOT/" + pkg.path
                for pkg in build_deps.to_list()
            ]),
        },
        command = """
log="$(mktemp)"
trap "rm $log" EXIT
# pip install.
if ! (%s >& log); then
  cat log
  exit 1
fi
# Apply any patches.
for patch in %s; do
  patch -s -t -d %s %s < "$patch" || exit 1
done
# Compile.
if ! (%s >& log); then
  cat log
  exit 1
fi
# Check.
if ! (%s >& log); then
  cat log
  exit 1
fi
""" % (
            " ".join([
                ctx.executable._pip.path,
                "install",
                "-vvv",
                "--no-compile",
                "--no-deps",
                "--no-index",
                "--no-cache-dir",
                "--no-binary=:all:",
                "--no-build-isolation",
                "--target",
                extracted_dir.path,
                ctx.file.path.path + (
                    "[" + ",".join(ctx.attr.extras) + "]" if ctx.attr.extras else ""
                ),
            ]),
            " ".join([patch.path for patch in ctx.files.patches]),
            extracted_dir.path,
            " ".join(ctx.attr.patch_args),
            " ".join([
                ctx.executable._pyc_compiler.path,
                "--invalidation-mode",
                "unchecked-hash",
                extracted_dir.path,
            ]),
            " ".join([
                "PYTHONPATH=$PYTHONPATH:" + extracted_dir.path,
                ctx.executable._pip.path,
                "check",
                "--disable-pip-version-check",
            ]),
        ),
        progress_message = "Setting up Pip package " + str(ctx.label),
        mnemonic = "PipInstall",
    )
    runfiles = ctx.runfiles(files = [extracted_dir]).merge(
        ctx.runfiles(ctx.files.deps, collect_default = True),
    )
    return [
        DefaultInfo(default_runfiles = runfiles),
        PyInfo(
            transitive_sources = depset([extracted_dir], transitive = [
                dep[PyInfo].transitive_sources
                for dep in ctx.attr.deps
                if PyInfo in dep
            ]),
            imports = depset(
                ["%s/%s" % (ctx.workspace_name, extracted_dir.short_path)],
                transitive = [
                    dep[PyInfo].imports
                    for dep in ctx.attr.deps
                    if PyInfo in dep
                ],
            ),
        ),
        ImportPipInfo(
            wheel = ctx.attr.path,
            extras = ctx.attr.extras,
            version = ctx.attr.version,
        ),
    ]

pip_import = rule(
    implementation = _pip_import_impl,
    fragments = ["cpp"],
    attrs = {
        "actual_import": attr.string(mandatory = False),
        "data": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [PyInfo]),
        "extras": attr.string_list(),
        "patch_args": attr.string_list(default = ["-p1"]),
        "patches": attr.label_list(allow_files = [".patch"]),
        "path": attr.label(allow_single_file = True),
        "version": attr.string(),
        "_cc_toolchain": attr.label(default = "@bazel_tools//tools/cpp:current_cc_toolchain"),
        "_ldshared": attr.label(
            cfg = "exec",
            default = "@dbx_build_tools//build_tools/py:ldshared-wrapper",
            executable = True,
        ),
        "_pip": attr.label(
            cfg = "exec",
            default = "//rules/pip",
            executable = True,
        ),
        "_pyc_compiler": attr.label(
            cfg = "exec",
            default = "//rules/pip:pyc_compiler",
            executable = True,
        ),
        "_python_headers": attr.label(
            default = "//rules/pip:python_headers",
        ),
    },
)
