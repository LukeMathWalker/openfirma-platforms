"""Repository extension for prebuilt prost codegen plugins."""

def _host_platform(repository_ctx):
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch.lower()

    if os_name.startswith("linux"):
        if arch in ("amd64", "x86_64"):
            return "x86_64-unknown-linux-gnu", "tar.gz", ""
    elif os_name.startswith("mac os") or os_name.startswith("darwin"):
        if arch in ("aarch64", "arm64"):
            return "aarch64-apple-darwin", "tar.gz", ""
        if arch in ("amd64", "x86_64"):
            return "x86_64-apple-darwin", "tar.gz", ""
    elif os_name.startswith("windows"):
        if arch in ("amd64", "x86_64"):
            return "x86_64-pc-windows-msvc", "zip", ".exe"

    fail("unsupported prost plugin host platform: os=%s arch=%s" % (repository_ctx.os.name, repository_ctx.os.arch))

def _prost_plugins_repository_impl(repository_ctx):
    triple, archive_ext, exe_ext = _host_platform(repository_ctx)
    version = repository_ctx.attr.version
    asset = "openfirma-prost-plugins-%s-%s.%s" % (version, triple, archive_ext)
    prefix = "openfirma-prost-plugins-%s-%s" % (version, triple)
    sha256 = repository_ctx.attr.sha256s.get(triple)

    if not sha256:
        fail("missing sha256 for prost plugin host triple %s" % triple)

    url = repository_ctx.attr.url_template.format(
        archive_ext = archive_ext,
        asset = asset,
        triple = triple,
        version = version,
    )

    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        stripPrefix = prefix,
    )

    repository_ctx.file(
        "prebuilt_binary.bzl",
        """def _prebuilt_binary_impl(ctx):
    binary = ctx.outputs.executable
    ctx.actions.symlink(
        output = binary,
        target_file = ctx.file.src,
        is_executable = True,
    )
    return [DefaultInfo(
        executable = binary,
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary, ctx.file.src]),
    )]

prebuilt_binary = rule(
    implementation = _prebuilt_binary_impl,
    attrs = {
        \"src\": attr.label(allow_single_file = True, mandatory = True),
    },
    executable = True,
)
""",
    )

    repository_ctx.file(
        "BUILD.bazel",
        """load(\":prebuilt_binary.bzl\", \"prebuilt_binary\")

package(default_visibility = [\"//visibility:public\"])

exports_files([
    \"bin/protoc-gen-prost{exe_ext}\",
    \"bin/protoc-gen-tonic{exe_ext}\",
])

prebuilt_binary(
    name = \"protoc-gen-prost\",
    src = \"bin/protoc-gen-prost{exe_ext}\",
)

prebuilt_binary(
    name = \"protoc-gen-tonic\",
    src = \"bin/protoc-gen-tonic{exe_ext}\",
)
""".format(exe_ext = exe_ext),
    )

prost_plugins_repository = repository_rule(
    implementation = _prost_plugins_repository_impl,
    attrs = {
        "sha256s": attr.string_dict(mandatory = True),
        "url_template": attr.string(default = "https://github.com/LukeMathWalker/openfirma-platforms/releases/download/v{version}/{asset}"),
        "version": attr.string(mandatory = True),
    },
)

def _prost_plugins_extension_impl(module_ctx):
    tags = []
    for module in module_ctx.modules:
        tags.extend(module.tags.release)

    if len(tags) != 1:
        fail("expected exactly one prost_plugins.release(...) tag")

    tag = tags[0]
    prost_plugins_repository(
        name = "openfirma_prost_plugins",
        sha256s = tag.sha256s,
        url_template = tag.url_template,
        version = tag.version,
    )

prost_plugins = module_extension(
    implementation = _prost_plugins_extension_impl,
    tag_classes = {
        "release": tag_class(attrs = {
            "sha256s": attr.string_dict(mandatory = True),
            "url_template": attr.string(default = "https://github.com/LukeMathWalker/openfirma-platforms/releases/download/v{version}/{asset}"),
            "version": attr.string(mandatory = True),
        }),
    },
)
