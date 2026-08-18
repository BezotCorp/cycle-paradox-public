#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: read-changelog-release.sh <changelog-path> <version>" >&2
  exit 2
fi

CHANGELOG_PATH="$1"
VERSION="$2"

awk -v expected_version="$VERSION" '
  /^## / {
    if (found) {
      exit
    }

    heading = $0
    sub(/^## +/, "", heading)

    version = heading
    sub(/^\[/, "", version)
    sub(/\].*$/, "", version)
    sub(/[[:space:]].*$/, "", version)

    if (version == expected_version) {
      found = 1
    }
  }

  found {
    print
  }

  END {
    if (!found) {
      exit 1
    }
  }
' "$CHANGELOG_PATH"
