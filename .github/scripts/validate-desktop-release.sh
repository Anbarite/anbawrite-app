#!/usr/bin/env bash

set -euo pipefail

tag="${1:?usage: validate-desktop-release.sh TAG RELEASE_JSON MANIFEST}"
release_json="${2:?usage: validate-desktop-release.sh TAG RELEASE_JSON MANIFEST}"
manifest="${3:?usage: validate-desktop-release.sh TAG RELEASE_JSON MANIFEST}"
version="${tag#desktop-v}"

jq -e --arg tag "$tag" '
  .tag_name == $tag and
  .draft == true and
  (.id | type == "number") and
  (.assets | type == "array")
' "$release_json" > /dev/null || {
  echo "Release data is not the expected draft for $tag." >&2
  exit 1
}

jq -e --arg version "$version" '
  . as $manifest |
  .version == $version and
  [
    "darwin-aarch64",
    "darwin-x86_64",
    "windows-x86_64-nsis"
  ] as $platforms |
  all(
    $platforms[];
    (. as $platform |
      ($manifest.platforms[$platform].signature |
        type == "string" and length > 0) and
      ($manifest.platforms[$platform].url |
        type == "string" and length > 0))
  )
' "$manifest" > /dev/null || {
  echo "latest.json is missing the expected version or updater platforms." >&2
  exit 1
}

resolve_asset_name() {
  local platform="$1"
  local url
  url="$(jq -er --arg platform "$platform" '.platforms[$platform].url' "$manifest")"

  jq -er --arg url "$url" --arg platform "$platform" '
    def without_query: sub("[?#].*$"; "");
    ($url | without_query) as $clean_url |
    [
      .assets[] |
      select(
        (.url | without_query) == $clean_url or
        (.browser_download_url | without_query) == $clean_url or
        (.id | tostring) == ($clean_url | split("/")[-1])
      ) |
      .name
    ] |
    if length == 1 then
      .[0]
    else
      error(
        "\($platform) updater URL identifies \(length) release assets, expected 1"
      )
    end
  ' "$release_json"
}

require_asset() {
  local asset="$1"
  jq -e --arg asset "$asset" '
    [.assets[] | select(.name == $asset)] | length == 1
  ' "$release_json" > /dev/null || {
    echo "Draft release must contain exactly one asset named: $asset" >&2
    exit 1
  }
}

arm_archive="$(resolve_asset_name darwin-aarch64)"
intel_archive="$(resolve_asset_name darwin-x86_64)"
windows_installer="$(resolve_asset_name windows-x86_64-nsis)"

if [[ "$arm_archive" != *.app.tar.gz ]]; then
  echo "The Apple Silicon updater URL does not reference an app archive." >&2
  exit 1
fi
if [[ "$intel_archive" != *.app.tar.gz ]]; then
  echo "The Intel macOS updater URL does not reference an app archive." >&2
  exit 1
fi
if [[ "$arm_archive" == "$intel_archive" ]]; then
  echo "The two macOS updater entries must reference distinct native archives." >&2
  exit 1
fi
if [[ "$windows_installer" != *-setup.exe ]]; then
  echo "The Windows NSIS updater URL does not reference an installer." >&2
  exit 1
fi

for asset in \
  latest.json \
  "$arm_archive" \
  "$arm_archive.sig" \
  "${arm_archive%.app.tar.gz}.dmg" \
  "$intel_archive" \
  "$intel_archive.sig" \
  "${intel_archive%.app.tar.gz}.dmg" \
  "$windows_installer" \
  "$windows_installer.sig"; do
  require_asset "$asset"
done

printf 'Validated updater assets:\n'
printf '  Apple Silicon: %s\n' "$arm_archive"
printf '  Intel macOS:   %s\n' "$intel_archive"
printf '  Windows NSIS:  %s\n' "$windows_installer"
