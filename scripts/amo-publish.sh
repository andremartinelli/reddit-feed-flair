#!/bin/sh
# Uploads a ZIP to Firefox Add-ons (AMO API v5) and submits it for review as a
# new listed version of the existing add-on (Firefox desktop only).
# Usage: AMO_JWT_ISSUER=... AMO_JWT_SECRET=... [RELEASE_NOTES=...] scripts/amo-publish.sh dist/file.zip
#        scripts/amo-publish.sh --check   (only reads the add-on status; changes nothing)
# The notes for Mozilla reviewers come from store/amo-approval-notes.txt.
# API docs: https://mozilla.github.io/addons-server/topics/api/addons.html
set -eu
arg="${1:?usage: scripts/amo-publish.sh <zip> | --check}"
: "${AMO_JWT_ISSUER:?AMO_JWT_ISSUER is not set}"
: "${AMO_JWT_SECRET:?AMO_JWT_SECRET is not set}"
root="$(dirname "$0")/.."
api="${AMO_API:-https://addons.mozilla.org/api/v5}"
guid=$(jq -r '.browser_specific_settings.gecko.id' "$root/manifest.json")
addon="$api/addons/addon/$(jq -rn --arg g "$guid" '$g | @uri')"

# A fresh JWT for each request (AMO wants a unique jti; it expires in 60 s).
# Node reads the secret from the environment, so it never shows up in a command line.
jwt() {
  node -e '
    const crypto = require("crypto");
    const b64 = (s) => Buffer.from(s).toString("base64url");
    const now = Math.floor(Date.now() / 1000);
    const head = b64(JSON.stringify({ alg: "HS256", typ: "JWT" }));
    const body = b64(JSON.stringify({
      iss: process.env.AMO_JWT_ISSUER, jti: crypto.randomUUID(), iat: now, exp: now + 60,
    }));
    const sig = crypto.createHmac("sha256", process.env.AMO_JWT_SECRET)
      .update(`${head}.${body}`).digest("base64url");
    process.stdout.write(`${head}.${body}.${sig}`);
  '
}

# Prints the response body; on an HTTP error prints it to stderr and fails.
# The Authorization header goes in through stdin, not the command line.
call() {
  if ! out=$(printf 'Authorization: JWT %s\n' "$(jwt)" | curl -sS --fail-with-body -H @- "$@"); then
    echo "$out" >&2
    return 1
  fi
  echo "$out"
}

# Results go through a variable before jq: in a pipeline a failed call would
# go unnoticed, because sh only checks the last command.
if [ "$arg" = "--check" ]; then
  out=$(call "$addon/")
  echo "$out" | jq '{
    guid, slug, status,
    current_version: .current_version.version,
    latest_listed_version: .latest_listed_version.version,
    latest_listed_file_status: .latest_listed_version.file.status
  }'
  exit 0
fi

zip="$arg"
echo "Uploading $zip"
res=$(call -F "upload=@$zip" -F "channel=listed" "$api/addons/upload/")
uuid=$(echo "$res" | jq -r '.uuid')

# Validation runs asynchronously: poll for up to 5 minutes.
tries=0
while [ "$(echo "$res" | jq -r '.processed')" != "true" ] && [ "$tries" -lt 60 ]; do
  sleep 5
  tries=$((tries + 1))
  res=$(call "$api/addons/upload/$uuid/")
done
echo "$res" | jq -r '.validation.messages[]? | "\(.type): \(.message)"'
if [ "$(echo "$res" | jq -r '.processed')" != "true" ]; then
  echo "::error::Validation did not finish in 5 minutes (upload $uuid)" >&2
  exit 1
fi
if [ "$(echo "$res" | jq -r '.valid')" != "true" ]; then
  echo "::error::The package failed AMO validation (see the messages above)" >&2
  exit 1
fi

echo "Submitting version $(echo "$res" | jq -r '.version') for review"
notes=$(printf '%s' "${RELEASE_NOTES:-}" | tr -d '\r')
body=$(jq -n --arg upload "$uuid" --arg notes "$notes" \
  --rawfile approval "$root/store/amo-approval-notes.txt" '
  { upload: $upload, compatibility: ["firefox"], approval_notes: $approval }
  + (if ($notes | length) > 0 then { release_notes: { "en-US": $notes } } else {} end)')
out=$(call -H 'Content-Type: application/json' --data-binary "$body" "$addon/versions/")
echo "$out" | jq '{ id, version, channel, file_status: .file.status }'
