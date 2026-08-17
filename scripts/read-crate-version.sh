#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: read-crate-version.sh <crate-name>" >&2
  exit 2
fi

CRATE_NAME="$1"

cargo metadata --no-deps --format-version 1 |
  jq --exit-status --raw-output \
    --arg crate_name "$CRATE_NAME" \
    '.packages[] | select(.name == $crate_name) | .version'
