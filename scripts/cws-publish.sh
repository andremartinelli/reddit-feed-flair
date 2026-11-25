#!/bin/sh
# Uploads a ZIP to the Chrome Web Store and submits it for review (API v2).
# Usage: CWS_TOKEN=... CWS_PUBLISHER_ID=... CWS_ITEM_ID=... scripts/cws-publish.sh dist/file.zip
#        scripts/cws-publish.sh --check   (only reads the item status; changes nothing)
#
# JSON is printed with printf, never echo: dash's echo (the /bin/sh on Ubuntu)
# turns the "\n" inside JSON strings into real newlines, and jq rejects that.
set -eu
zip="${1:?usage: scripts/cws-publish.sh <zip> | --check}"
: "${CWS_TOKEN:?CWS_TOKEN is not set}"
: "${CWS_PUBLISHER_ID:?CWS_PUBLISHER_ID is not set}"
: "${CWS_ITEM_ID:?CWS_ITEM_ID is not set}"
api="${CWS_API:-https://chromewebstore.googleapis.com}"
item="publishers/$CWS_PUBLISHER_ID/items/$CWS_ITEM_ID"

# Prints the response body; on an HTTP error prints it to stderr and fails.
call() {
  if ! out=$(curl -sS --fail-with-body -H "Authorization: Bearer $CWS_TOKEN" "$@"); then
    printf '%s\n' "$out" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

if [ "$zip" = "--check" ]; then
  call "$api/v2/$item:fetchStatus"
  exit 0
fi

if [ ! -s "$zip" ]; then
  echo "::error::ZIP not found or empty: '$zip'" >&2
  exit 1
fi

echo "Uploading $zip"
res=$(call -X POST -T "$zip" "$api/upload/v2/$item:upload")
printf '%s\n' "$res"
state=$(printf '%s\n' "$res" | jq -r '.uploadState')

# Large uploads are processed asynchronously: poll for up to 2 minutes.
tries=0
while [ "$state" = "IN_PROGRESS" ] && [ "$tries" -lt 24 ]; do
  sleep 5
  tries=$((tries + 1))
  # Kept in a variable first: in a pipeline a failed call would go unnoticed.
  res=$(call "$api/v2/$item:fetchStatus")
  state=$(printf '%s\n' "$res" | jq -r '.lastAsyncUploadState')
done
if [ "$state" != "SUCCEEDED" ]; then
  echo "::error::Upload did not succeed (state: $state)" >&2
  exit 1
fi

echo "Submitting for review"
call -X POST -H 'Content-Type: application/json' -d '{"publishType":"DEFAULT_PUBLISH"}' "$api/v2/$item:publish"
