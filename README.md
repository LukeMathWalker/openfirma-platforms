# OpenFirma Platforms

Bazel platform and toolchain definitions shared by OpenFirma repositories.

The first package owns platform labels that do not depend on OpenFirma's Cargo
workspace. OpenFirma can consume these labels through Bzlmod while keeping its
application crate graph local to the application repository.

During local development, OpenFirma uses a `local_path_override` pointing at this
sibling checkout. CI should switch to a pinned archive or module release once the
platform package is tagged.
