#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: run-semantic-release-version.sh <version>" >&2
  exit 2
fi

NEW_VERSION="$1"

echo "Recording HEAD before version preparation..."
BEFORE_SHA=$(git rev-parse HEAD)

RELEASE_DATA_DIRECTORY=$(mktemp -d)
trap 'rm -rf "$RELEASE_DATA_DIRECTORY"' EXIT

export RELEASE_NOTES_FILE="$RELEASE_DATA_DIRECTORY/notes"

node scripts/prepare-release-version.mjs "$NEW_VERSION"
semantic-release-cargo prepare "$NEW_VERSION"

COMMIT_MESSAGE_FILE="$RELEASE_DATA_DIRECTORY/commit-message"

{
  printf 'chore: %s [skip ci]\n\n' "$NEW_VERSION"
  cat "$RELEASE_NOTES_FILE"
} > "$COMMIT_MESSAGE_FILE"

git add \
  Cargo.lock \
  cycle_paradox_extension_api/Cargo.toml \
  cycle_paradox_extension_api/CHANGELOG.md

git commit --file "$COMMIT_MESSAGE_FILE"

AFTER_SHA=$(git rev-parse HEAD)

if [ "$BEFORE_SHA" = "$AFTER_SHA" ]; then
  echo "::error::No version commit was created."
  exit 1
fi

git push origin HEAD:release/pending

echo "::notice::Version bump confirmed — new version is $NEW_VERSION"
echo "Version bump confirmed — HEAD moved from $BEFORE_SHA to $AFTER_SHA, version $NEW_VERSION."
