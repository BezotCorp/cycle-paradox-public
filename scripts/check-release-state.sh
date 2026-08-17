#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: check-release-state.sh <crate-name> <owner/repository>" >&2
  exit 2
fi

CRATE_NAME="$1"
REPOSITORY="$2"
OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/stdout}"

CURRENT_VERSION="$(
  ./scripts/read-crate-version.sh "$CRATE_NAME"
)"

printf 'current_version=%s\n' "$CURRENT_VERSION" >> "$OUTPUT_FILE"

set +e
./scripts/check-rust-publication.sh \
  "$CRATE_NAME" \
  "$CURRENT_VERSION" \
  "$REPOSITORY"
PUBLICATION_STATUS=$?
set -e

case "$PUBLICATION_STATUS" in
  0)
    printf 'current_version_published=true\n' >> "$OUTPUT_FILE"
    ;;
  1)
    printf 'current_version_published=false\n' >> "$OUTPUT_FILE"
    ;;
  *)
    echo "failed to determine publication state" >&2
    exit "$PUBLICATION_STATUS"
    ;;
esac

rm -f .next-release-version
trap 'rm -f .next-release-version' EXIT

pnpm exec semantic-release --dry-run

if [ -s .next-release-version ]; then
  NEXT_VERSION="$(
    tr -d '\r\n' < .next-release-version
  )"

  printf 'has_new_version=true\n' >> "$OUTPUT_FILE"
  printf 'next_version=%s\n' "$NEXT_VERSION" >> "$OUTPUT_FILE"

  echo "semantic-release selected version $NEXT_VERSION"
else
  printf 'has_new_version=false\n' >> "$OUTPUT_FILE"
  printf 'next_version=\n' >> "$OUTPUT_FILE"

  echo "semantic-release found no new version"
fi
