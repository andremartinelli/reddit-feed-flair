# Feed Flair for Reddit

[Português](README.pt-BR.md)

A browser extension that shows each post's flair on Reddit's main feeds (Home, Popular, All and custom feeds), with the original text, emojis and colors, next to "r/subreddit • time".

New Reddit hides post flair on these feeds. This extension puts it back.

Unofficial. Not affiliated with or endorsed by Reddit, Inc.

## Install

From the Chrome Web Store: [Feed Flair for Reddit](https://chromewebstore.google.com/detail/ljipmpigkkjkbodimengbbacakngcceo).

From source (to run the latest code before it is released):

Tested in Brave. It is a standard Manifest V3 extension, so it should also work in Chrome, Edge and other Chromium browsers.

1. Download or clone this repository.
2. Open `brave://extensions` (or `chrome://extensions`, `edge://extensions`).
3. Turn on **Developer mode** (top right).
4. Click **Load unpacked** and pick the `reddit-feed-flair` folder.
5. Reload reddit.com.

After changing any file, click the reload button on the extension's card and reload Reddit.

Don't keep the store version installed in the same browser: both copies would run, each post would be fetched twice, and the store copy may draw the badge before yours.

## How it works

- On the main feed, Reddit puts an empty `<shreddit-post-flair>` in every post. The extension only treats a post as already showing its flair when that element has text or an emoji.
- For each visible post without flair, it fetches `/comments/<id>.json` using your Reddit session: 4 requests at a time, top posts first. If Reddit answers 429 (too many requests), it waits 5 seconds and tries again.
- If the JSON fails, it opens the post page and reads the flair from there (heavier, and without colors).
- Each flair is cached for 24 hours in the extension's local storage (up to 3,000 posts). When you reload or go back to the feed, posts you've already seen show their flair right away, with no new request. Failed fetches are not cached.
- It looks for new posts at most every 200 ms, even while Reddit keeps changing the page.
- It does nothing on a post's own page.

## Privacy

- No external server. The only requests go to www.reddit.com, with your own session, the same way the page itself does.
- Permissions: run on www.reddit.com, and `storage` for the cache above.

Tested on 2026-11-23: the batch endpoints (`/api/info.json` and `/by_id/...json`) return 403 to the browser, so the extension fetches one post at a time.

## If it stops working

In `content.js`, set `DEBUG` to `true`, reload the extension and Reddit. A yellow panel shows up in the corner with how many posts were found, how many badges were drawn and the result of the requests.

The parts that depend on Reddit's HTML:

- `shreddit-post` and the post's `id` and `permalink` attributes;
- `[id*='credit-bar']`, the line where the badge goes;
- `shreddit-post-flair`, the flair Reddit draws itself.

Errors show up in the page console with the `[Feed Flair for Reddit]` prefix.

## Releasing a new version

1. Change the code and test it: reload the extension in `brave://extensions`, then reload Reddit.
2. Raise `version` in `manifest.json` (for example 1.3.0 → 1.3.1). The Chrome Web Store rejects a package whose version isn't higher than the published one.
3. Commit and push.
4. Create a GitHub Release with tag `v<version>`, for example `gh release create v1.3.1 --generate-notes`. The **Publish to Chrome Web Store** workflow builds the ZIP and submits it for review. Setup and details: `store/automation.md`.

Manual fallback: run `./build.sh` and upload `dist/feed-flair-for-reddit-<version>.zip` in the [Chrome Web Store dashboard](https://chrome.google.com/webstore/devconsole), on the item's **Package** tab.

Store texts and answers live in `store/listing.md`. If you change them in the dashboard, update that file too.

## License

[MIT](LICENSE)
