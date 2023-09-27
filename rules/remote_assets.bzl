"""Repository rule for using remote assets available over HTTP.

File pointers are given in a .json file:

    [{
        "name": "file1",
        "url": "http://asset/download_url1",
        "sha256": "hash1",
    }, {
        "name": "path/to/file2",
        "urls": ["http://asset/download_url2"],
        "sha256": "hash2",
    }]

To expose the files in the workspace, call the rule from WORKSPACE and execute
the load function:

    load("//rules:remote_assets.bzl", "remote_assets")
    remote_assets(
        name = "asset_repo_name",
        spec = "//path/to:spec.json",
       [visibility = ["//visibility:public"],]
    )

    load("@asset_repo_name//:repositories.bzl", configure_my_assets = "configure_assets")
    configure_my_assets()

Files will be then available under @asset_repo_name at the specified path, e.g.
"@asset_repo_name//:file1", "@asset_repo_name//path/to:file2".

Under the hood these are aliases to individual repositories created for those
files, so they are lazily-loaded when requested.
"""

_repositories_bzl_tmpl = """load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

def configure_assets(): {repositories}
"""

def _file_repo(name, filename):
    return name + "__" + filename.replace("/", "__")

def _http_file(name, urls, sha256, strip_prefix, remote_assets_repo):
    return """
    http_file(
        name = "{name}",
        downloaded_file_path = "_file",
        urls = {urls},
        sha256 = "{sha256}",
    )""".format(name = name, urls = urls, sha256 = sha256)

def _filegroup(name, files, visibility):
    return """
filegroup(
    name = "{name}",
    srcs = {files},
    visibility = {visibility},
)
""".format(name = name, files = files, visibility = visibility)

def _symlink(name, file, visibility):
    return """
symlink(
    name = "{name}",
    src = "{file}",
    visibility = {visibility},
)
""".format(name = name, file = file, visibility = visibility)

def _symlink_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output = output, target_file = ctx.attr.src.files.to_list()[0])
    return [DefaultInfo(
        files = depset([output]),
        runfiles = ctx.runfiles(files = [output]),
    )]

symlink = rule(
    implementation = _symlink_impl,
    attrs = {
        "src": attr.label(allow_single_file = True),
    },
)

def _remote_assets_impl(ctx):
    spec = json.decode(ctx.read(ctx.attr.spec))
    visibility = [str(label) for label in ctx.attr.visibility] or ["//visibility:public"]

    repositories = []
    packages = {}
    for f in spec:
        name, urls, sha256 = (
            f["name"],
            f.get("urls", [f.get("url")]),
            f["sha256"],
        )

        file_repo = _file_repo(ctx.name, name)
        repositories.append(_http_file(
            name = file_repo,
            urls = urls,
            sha256 = sha256,
            strip_prefix = f.get("strip_prefix"),
            remote_assets_repo = ctx.name,
        ))

        dirname, _, basename = name.rpartition("/")
        if dirname not in packages:
            packages[dirname] = {}
        packages[dirname][basename] = "@{file_repo}//file".format(file_repo = file_repo)

    for package, files in packages.items():
        package_dir = ctx.path(package)
        ctx.file(
            package_dir.get_child("BUILD"),
            content = """load("@//rules:remote_assets.bzl", "symlink")
""" + "\n".join([
                _symlink(
                    name = filename,
                    file = origin,
                    visibility = visibility,
                )
                for filename, origin in files.items()
            ]),
            executable = False,
        )

    if "" not in packages:
        ctx.file("BUILD")
    ctx.file("repositories.bzl", _repositories_bzl_tmpl.format(
        repositories = "\n".join(repositories) or "pass",
    ))

remote_assets = repository_rule(
    implementation = _remote_assets_impl,
    attrs = {
        "spec": attr.label(allow_single_file = True),
    },
)
