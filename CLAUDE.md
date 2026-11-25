# Instructions for Claude Code

Feed Flair for Reddit: a Manifest V3 browser extension with no dependencies
(`content.js`, `style.css`, `manifest.json`, `_locales/`). See `README.md`.

## Checks (same as CI, run before every commit)

```sh
node --check content.js
for f in manifest.json _locales/*/messages.json; do jq empty "$f"; done
./build.sh   # writes dist/feed-flair-for-reddit-<version>.zip (git-ignored)
```

There are no unit tests. Behavior is tested by loading the unpacked extension
in a Chromium browser or in Firefox (see README "Install").

Cloud sessions: `scripts/cloud-setup.sh` installs what is missing (jq, zip) and
runs from the SessionStart hook in `.claude/settings.json` only when
`CLAUDE_CODE_REMOTE=true`.

## Production is off limits

- Never create a GitHub Release or tag, and never run the publishing
  workflows, not even their check jobs: "Publish to Chrome Web Store"
  (`.github/workflows/publish.yml`) and "Publish to Firefox Add-ons"
  (`.github/workflows/publish-firefox.yml`).
- Never run `scripts/cws-publish.sh` or call the Chrome Web Store API.
- Don't offer to fill in the Chrome Web Store developer dashboard: no browser
  Claude has can operate it (the app's browser doesn't load the page, and
  Claude in Chrome fails with "The extensions gallery cannot be scripted").
  To update the store, prepare the ZIP (`./build.sh`) and the texts in
  `store/listing.md`, then give the owner a numbered list of steps to do in
  the dashboard.
- Never submit to Firefox Add-ons (addons.mozilla.org) or call its API,
  including `web-ext sign` and `scripts/amo-publish.sh`. Testing that script
  against a local fake server through `AMO_API` is fine.
- Never ask for, print or store secrets or the `GCP_*`/`CWS_*`/`AMO_*` values.
- Don't raise `version` in `manifest.json` unless asked.

## Working rules

- Code, commits and docs in this repo stay in English.
- Open pull requests, never merge them.
