# AnbaWrite Desktop Releases

This binary-only repository distributes public, signed AnbaWrite installers
for macOS and Windows. GitHub Releases also provide the metadata and signatures
used by the Tauri desktop updater.

AnbaWrite's source code remains private in
[`Anbarite/anbawrite`](https://github.com/Anbarite/anbawrite).
Release automation checks out tagged source with a repository-scoped,
read-only token; no source code is published here.

Each desktop release is assembled as a draft by the macOS and Windows matrix
builds. After both builds succeed, automation downloads and validates the
updater manifest, its platform URLs and signatures, and the expected macOS and
Windows installer assets. Only a complete, valid draft is published and marked
as the latest release; failed builds or validation leave the release as a
draft. Rerunning an already-published tag is a safe no-op.
