# Firefox Add-ons listing

How to submit the extension to Firefox Add-ons (addons.mozilla.org, "AMO") and the text to paste in each field. Firefox-specific settings live in `manifest.json` under `browser_specific_settings.gecko`.

Decided on 2026-11-24:

- Add-on ID: `feed-flair@andremartinelli`. AMO ties the listing to this ID, so it can never change.
- Firefox desktop only (140 or later). Firefox for Android isn't tested.
- The first version was uploaded by hand in the Developer Hub. Later versions go out through the "Publish to Firefox Add-ons" workflow when a GitHub Release is published (decided 2026-11-25; see `store/automation.md`).
- Data collection: `"required": ["none"]`. This is the same answer as in the Chrome Web Store: nothing leaves the browser except the requests to www.reddit.com that the page itself makes.

## Before the first upload

1. Test in Firefox 140 or later. See README "Install".
2. Create an account at https://addons.mozilla.org/developers/. It's free.
3. Run `./build.sh` and use `dist/feed-flair-for-reddit-<version>.zip`, the same package as the Chrome Web Store.

## Submit a New Add-on

**How to distribute this version:** On this site.

**Upload version:** pick the ZIP. Compatible platforms: check **Firefox** and uncheck **Firefox for Android**.

**Source code:** No. The ZIP holds the source as written: no minifier, bundler or build step.

### Describe add-on

**Name:** comes from `_locales/en/messages.json` (Feed Flair for Reddit).

**Add-on URL:** `feed-flair-for-reddit`

**Summary** (250 characters max; comes from `extDescription`):

```
Shows post flair on Reddit's Home, Popular, All and custom feeds, with the original emojis and colors.
```

**Description:** same English text as the Chrome listing in `store/listing.md`.

**Experimental:** no. **Requires payment:** no.

**Categories:** Social & Communication. If it asks for a second one, pick Appearance.

**Support email:** leave empty.

**Support website:**

```
https://github.com/andremartinelli/reddit-feed-flair/issues
```

**License:** The MIT License.

**Privacy policy:** check "This add-on has a privacy policy" and paste the English part of `PRIVACY.md`, from "Feed Flair for Reddit does not collect" to the Contact section.

**Notes to reviewer:** paste the contents of `store/amo-approval-notes.txt`. The publishing workflow sends the same file with every new version, so edit it there.

Never put a real Reddit username or password here. AMO's checklist asks for a test account only when one is needed, and this extension doesn't need one.

**Release notes** (first version):

```
First release on Firefox Add-ons. Shows each post's flair on Reddit's Home, Popular, All and custom feeds, with the original text, emojis and colors. Same features as version 1.3.0 on the Chrome Web Store.
```

## After the first approval

1. **Edit Product Page:**
   - Add the screenshot `store/screenshot-1280x800.png`.
   - Set the homepage to `https://github.com/andremartinelli/reddit-feed-flair`.
   - Add Portuguese (Brazil) as a locale. Use the Portuguese description from `store/listing.md` and this summary:

     ```
     Mostra a flair dos posts nos feeds Home, Popular, All e personalizados do Reddit, com os emojis e as cores originais.
     ```

2. Add the Firefox Add-ons link to "Install" in `README.md` and `README.pt-BR.md`.

## New versions

Publishing a GitHub Release sends them automatically: see `store/automation.md`. The release text becomes the release notes, and `store/amo-approval-notes.txt` becomes the notes to reviewer.

Manual fallback:

1. Raise `version` in `manifest.json`. AMO rejects a version that isn't higher than the published one.
2. Run `./build.sh`.
3. In the Developer Hub, open the add-on and click **Upload New Version**. Give the same answers as above: Firefox only, no source code. Write release notes about what changed, and paste `store/amo-approval-notes.txt` as the notes to reviewer.
