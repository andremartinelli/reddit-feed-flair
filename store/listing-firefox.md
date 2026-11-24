# Firefox Add-ons listing

How to submit the extension to Firefox Add-ons (addons.mozilla.org, "AMO") and the text to paste in each field. Firefox-specific settings live in `manifest.json` under `browser_specific_settings.gecko`.

Decided on 2026-11-24:

- Add-on ID: `feed-flair@andremartinelli`. AMO ties the listing to this ID, so it can never change.
- Firefox desktop only (140 or later). Firefox for Android isn't tested.
- Manual upload in the Developer Hub. There's no publishing workflow for Firefox.
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

**Notes to reviewer:**

```
No build step: the ZIP is the source as written (content.js, style.css, manifest.json, _locales, icons). Source: https://github.com/andremartinelli/reddit-feed-flair

How to test: open https://www.reddit.com/ (Home, r/popular or r/all). Posts whose flair Reddit hides on these feeds get a badge next to "r/subreddit • time". The content script only runs on www.reddit.com and only fetches www.reddit.com/comments/<id>.json (or the post page as a fallback). It caches the flair in storage.local for 24 hours. No remote code, no other hosts.
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

1. Raise `version` in `manifest.json`. AMO rejects a version that isn't higher than the published one.
2. Run `./build.sh`.
3. In the Developer Hub, open the add-on and click **Upload New Version**. Give the same answers as above: Firefox only, no source code.
