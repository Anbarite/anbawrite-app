#!/usr/bin/env bash

set -euo pipefail

tag="${1:?usage: find-desktop-release.sh TAG OUTPUT [ATTEMPTS]}"
output="${2:?usage: find-desktop-release.sh TAG OUTPUT [ATTEMPTS]}"
attempts="${3:-6}"

if [[ ! "$attempts" =~ ^[1-9][0-9]*$ ]]; then
  echo "ATTEMPTS must be a positive integer." >&2
  exit 2
fi

pages="$(mktemp)"
trap 'rm -f "$pages"' EXIT
last_listing_succeeded=false

for ((attempt = 1; attempt <= attempts; attempt++)); do
  if gh api --paginate --slurp \
    "repos/$GITHUB_REPOSITORY/releases?per_page=100" > "$pages"; then
    last_listing_succeeded=true
    match_count="$(
      jq -er --arg tag "$tag" '
        [.[][] | select(type == "object" and .tag_name == $tag)] | length
      ' "$pages"
    )"

    if ((match_count > 1)); then
      echo "Found multiple releases with exact tag $tag; refusing to choose one." >&2
      exit 2
    fi

    if ((match_count == 1)); then
      jq -e --arg tag "$tag" '
        [.[][] | select(type == "object" and .tag_name == $tag)][0]
      ' "$pages" > "$output"
      exit 0
    fi

    echo "Release $tag was not visible on attempt $attempt of $attempts." >&2
  else
    last_listing_succeeded=false
    echo "GitHub release listing failed on attempt $attempt of $attempts." >&2
  fi

  if ((attempt < attempts)); then
    delay=$((1 << (attempt - 1)))
    if ((delay > 16)); then
      delay=16
    fi
    sleep "$delay"
  fi
done

if [[ "$last_listing_succeeded" != "true" ]]; then
  echo "The final GitHub release listing attempt failed." >&2
  exit 3
fi

echo "No release with exact tag $tag was found after $attempts attempts." >&2
exit 4
