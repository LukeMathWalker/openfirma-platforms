# OpenFirma Platforms

Bazel platform and toolchain definitions shared by OpenFirma repositories.

The first package owns platform labels that do not depend on OpenFirma's Cargo
workspace. OpenFirma can consume these labels through Bzlmod while keeping its
application crate graph local to the application repository.

During local development, OpenFirma uses a `local_path_override` pointing at this
sibling checkout. CI should switch to a pinned archive or module release once the
platform package is tagged.

Tagged releases publish `openfirma-platforms-${VERSION}.tar.gz` and a matching
`.sha256` file. Downstream repositories can consume that archive with a Bzlmod
`archive_override` using `strip_prefix = "openfirma-platforms-${VERSION}"`.

Releases also publish host-specific `openfirma-prost-plugins-*` archives with
prebuilt `protoc-gen-prost` and `protoc-gen-tonic` binaries. Downstream modules
can load `@openfirma_platforms//toolchains:prost_plugins.bzl`, call
`prost_plugins.release(...)` with the release version and platform checksums, and
then use the generated `@openfirma_prost_plugins` repository.

```starlark
prost_plugins = use_extension(
    "@openfirma_platforms//toolchains:prost_plugins.bzl",
    "prost_plugins",
)
prost_plugins.release(
    version = "0.2.1",
    sha256s = {
        "aarch64-apple-darwin": "...",
        "x86_64-pc-windows-msvc": "...",
        "x86_64-unknown-linux-gnu": "...",
    },
)
use_repo(prost_plugins, "openfirma_prost_plugins")
```
