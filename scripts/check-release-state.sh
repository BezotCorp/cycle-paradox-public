#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: check-release-state.sh <crate-name> <owner/repository>" >&2
  exit 2
fi

CRATE_NAME="$1"
REPOSITORY="$2"
OUTPUT_FILE="${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

CURRENT_VERSION="$(
  ./scripts/read-crate-version.sh "$CRATE_NAME"
)"

printf 'current_version=%s\n' "$CURRENT_VERSION" >>"$OUTPUT_FILE"

set +e
PUBLICATION_OUTPUT="$(
  ./scripts/check-rust-publication.sh \
    "$CRATE_NAME" \
    "$CURRENT_VERSION" \
    "$REPOSITORY"
)"
PUBLICATION_STATUS=$?
set -e

if [ "$PUBLICATION_STATUS" -gt 1 ]; then
  echo "$PUBLICATION_OUTPUT" >&2
  echo "failed to determine publication state" >&2
  exit "$PUBLICATION_STATUS"
fi

printf '%s\n' "$PUBLICATION_OUTPUT"

PUBLICATION_STATE="$(
  printf '%s\n' "$PUBLICATION_OUTPUT" |
    sed -n 's/^publication_state=//p'
)"

case "$PUBLICATION_STATE" in
  complete)
    printf 'current_version_published=true\n' >>"$OUTPUT_FILE"
    ;;
  partial | absent)
    printf 'current_version_published=false\n' >>"$OUTPUT_FILE"
    ;;
  *)
    echo "invalid publication state: $PUBLICATION_STATE" >&2
    exit 3
    ;;
esac

printf 'current_version_publication_state=%s\n' "$PUBLICATION_STATE" >>"$OUTPUT_FILE"

pnpm exec semantic-release --dry-run

NEXT_VERSION="$(
  sed -n 's/^next_version=//p' "$OUTPUT_FILE" |
    tail -n 1
)"

if [ -n "$NEXT_VERSION" ]; then
  printf 'has_new_version=true\n' >>"$OUTPUT_FILE"

  echo "semantic-release selected version $NEXT_VERSION"
else
  printf 'has_new_version=false\n' >>"$OUTPUT_FILE"
  printf 'next_version=\n' >>"$OUTPUT_FILE"

  if [ "$PUBLICATION_STATE" = absent ]; then
    echo "::error::Version $CURRENT_VERSION is absent from crates.io and GitHub, but no prepared release version exists. Refusing direct publication."
    exit 1
  fi

  echo "semantic-release found no new version"
fi
