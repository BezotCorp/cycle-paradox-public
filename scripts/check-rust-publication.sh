#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: check-rust-publication.sh <crate-name> <version> <owner/repository>" >&2
  exit 2
fi

CRATE_NAME="$1"
VERSION="$2"
REPOSITORY="$3"

CRATES_IO_STATUS="$(
  curl \
    --silent \
    --show-error \
    --output /dev/null \
    --write-out '%{http_code}' \
    --header 'User-Agent: cycle-paradox-release-automation (https://github.com/BezotCorp/cycle-paradox-public)' \
    "https://crates.io/api/v1/crates/$CRATE_NAME/$VERSION"
)"

case "$CRATES_IO_STATUS" in
  200)
    CRATE_PUBLISHED=true
    ;;
  404)
    CRATE_PUBLISHED=false
    ;;
  *)
    echo "crates.io returned HTTP $CRATES_IO_STATUS" >&2
    exit 3
    ;;
esac

ERROR_FILE="$(mktemp)"
trap 'rm -f "$ERROR_FILE"' EXIT

if gh api \
    "repos/$REPOSITORY/releases/tags/$VERSION" \
    --silent \
    >/dev/null 2>"$ERROR_FILE"
then
  GITHUB_RELEASE_PUBLISHED=true
elif grep -Eq 'HTTP 404|Not Found' "$ERROR_FILE"; then
  GITHUB_RELEASE_PUBLISHED=false
else
  cat "$ERROR_FILE" >&2
  exit 3
fi

case "$CRATE_PUBLISHED:$GITHUB_RELEASE_PUBLISHED" in
  true:true)
    PUBLICATION_STATE=complete
    ;;
  false:false)
    PUBLICATION_STATE=absent
    ;;
  true:false | false:true)
    PUBLICATION_STATE=partial
    ;;
  *)
    echo "invalid publication state" >&2
    exit 3
    ;;
esac

printf 'crate_published=%s\n' "$CRATE_PUBLISHED"
printf 'github_release_published=%s\n' "$GITHUB_RELEASE_PUBLISHED"
printf 'publication_state=%s\n' "$PUBLICATION_STATE"

if [ "$PUBLICATION_STATE" = complete ]; then
  exit 0
fi

exit 1
