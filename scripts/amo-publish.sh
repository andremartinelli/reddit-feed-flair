#!/bin/sh
# Uploads a ZIP to Firefox Add-ons (AMO API v5) and submits it for review as a
# new listed version of the existing add-on (Firefox desktop only).
# Usage: AMO_JWT_ISSUER=... AMO_JWT_SECRET=... [RELEASE_NOTES=...] scripts/amo-publish.sh dist/file.zip
#        scripts/amo-publish.sh --check   (only reads the add-on status; changes nothing)
# The notes for Mozilla reviewers come from store/amo-approval-notes.txt.
# If the version is already on AMO (for example, when re-running a job), it exits 0 without uploading.
# API docs: https://mozilla.github.io/addons-server/topics/api/addons.html
#
# JSON is printed with printf, never echo: dash's echo (the /bin/sh on Ubuntu)
# turns the "\n" inside JSON strings into real newlines, and jq rejects that.
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

# curl with the Authorization header, which goes in through stdin, not the command line.
amo_curl() {
  printf 'Authorization: JWT %s\n' "$(jwt)" | curl -sS -H @- "$@"
}

# Prints the response body; on an HTTP error prints it to stderr and fails.
# Callers keep the result in a variable before using jq: in a pipeline a failed
# call would go unnoticed, because sh only checks the last command.
call() {
  if ! out=$(amo_curl --fail-with-body "$@"); then
    printf '%s\n' "$out" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

# Same as call, but tries 3 times, 5 s apart (for reads that are safe to repeat).
call_retry() {
  for attempt in 1 2 3; do
    if out=$(call "$@"); then
      printf '%s\n' "$out"
      return 0
    fi
    [ "$attempt" -lt 3 ] && sleep 5
  done
  return 1
}

if [ "$arg" = "--check" ]; then
  detail=$(call "$addon/")
  latest=$(call "$addon/versions/?filter=all_without_unlisted&page_size=1")
  jq -n --argjson a "$detail" --argjson v "$latest" '{
    guid: $a.guid, slug: $a.slug, status: $a.status,
    current_version: $a.current_version.version,
    latest_listed_version: $v.results[0].version,
    latest_listed_file_status: $v.results[0].file.status
  }'
  exit 0
fi

zip="$arg"
version=$(unzip -p "$zip" manifest.json | jq -r '.version')

# Stop early if this version was already submitted (a re-run after a partial failure).
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
code=$(amo_curl -o "$tmp" -w '%{http_code}' "$addon/versions/v$version/")
case "$code" in
  200)
    echo "Version $version is already on Firefox Add-ons (file status: $(jq -r '.file.status' "$tmp")). Nothing to upload."
    exit 0
    ;;
  404) ;;
  *)
    cat "$tmp" >&2
    echo >&2
    echo "::error::Could not check whether version $version exists (HTTP $code)" >&2
    exit 1
    ;;
esac

echo "Uploading $zip (version $version)"
res=$(call -F "upload=@$zip" -F "channel=listed" "$api/addons/upload/")
uuid=$(printf '%s\n' "$res" | jq -r '.uuid')

# Validation runs asynchronously: poll for up to 5 minutes.
tries=0
while [ "$(printf '%s\n' "$res" | jq -r '.processed')" != "true" ] && [ "$tries" -lt 60 ]; do
  sleep 5
  tries=$((tries + 1))
  res=$(call_retry "$api/addons/upload/$uuid/")
done
printf '%s\n' "$res" | jq -r '.validation.messages[]? | "\(.type): \(.message)"'
if [ "$(printf '%s\n' "$res" | jq -r '.processed')" != "true" ]; then
  echo "::error::Validation did not finish in 5 minutes (upload $uuid)" >&2
  exit 1
fi
if [ "$(printf '%s\n' "$res" | jq -r '.valid')" != "true" ]; then
  echo "::error::The package failed AMO validation (see the messages above)" >&2
  exit 1
fi

echo "Submitting version $version for review"
notes=$(printf '%s' "${RELEASE_NOTES:-}" | tr -d '\r')
body=$(jq -n --arg upload "$uuid" --arg notes "$notes" \
  --rawfile approval "$root/store/amo-approval-notes.txt" '
  { upload: $upload, compatibility: ["firefox"], approval_notes: $approval }
  + (if ($notes | length) > 0 then { release_notes: { "en-US": $notes } } else {} end)')
out=$(call -H 'Content-Type: application/json' --data-binary "$body" "$addon/versions/")
printf '%s\n' "$out" | jq '{ id, version, channel, file_status: .file.status }'
