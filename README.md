# AnbaWrite Desktop Releases

This binary-only repository distributes public, signed AnbaWrite installers
for macOS and Windows. GitHub Releases also provide the metadata and signatures
used by the Tauri desktop updater.

AnbaWrite's source code remains private in
[`Anbarite/anbawrite`](https://github.com/Anbarite/anbawrite).
Release automation checks out tagged source with a repository-scoped,
read-only token; no source code is published here.

Each desktop release is assembled as a draft by serialized Apple Silicon,
Intel macOS, and Windows matrix builds. Serial uploads preserve every platform
entry while `latest.json` is merged. After all builds succeed, automation
downloads and validates the updater manifest, its platform URLs and signatures,
and the expected macOS and Windows installer assets. Only the exact matching,
complete draft is published and marked as the latest release; failed builds or
validation leave the release as a draft. Rerunning an already-published tag is
a safe no-op.
