# Store listings

Texts and answers for the Chrome Web Store and Firefox Add-ons dashboards. The name and the short summary come from `_locales/*/messages.json`.

## Chrome Web Store

### Store listing tab

**Category:** Social Networking (or the closest "Social" category the dashboard offers)

**Language:** English (default). Add Portuguese (Brazil) as a second listing.

**Images:**
- Store icon: `icons/icon-128.png`
- Screenshot (1280x800): `store/screenshot-1280x800.png`
- Small promo tile (440x280): `store/promo-tile-440x280.png`

#### Description — English

```
New Reddit hides post flair on its main feeds. Feed Flair for Reddit puts it back.

On Home, Popular, All and your custom feeds, each post shows its flair next to "r/subreddit • time", with the original text, emojis and colors.

• Works on www.reddit.com (new Reddit).
• Does nothing where Reddit already shows the flair, such as a post's own page.
• Remembers each flair for 24 hours, so posts you've seen show up instantly.
• No external servers, no analytics, no tracking. It only talks to www.reddit.com, with your own session.

Open source (MIT): https://github.com/andremartinelli/reddit-feed-flair

Unofficial. Not affiliated with or endorsed by Reddit, Inc.
```

#### Descrição — Português (Brasil)

```
O Reddit novo esconde a flair dos posts nos feeds principais. A Feed Flair for Reddit põe de volta.

Na Home, no Popular, no All e nos seus feeds personalizados, cada post mostra a flair ao lado de "r/subreddit • tempo", com o texto, os emojis e as cores originais.

• Funciona no www.reddit.com (Reddit novo).
• Não mexe onde o Reddit já mostra a flair, como a página do próprio post.
• Lembra cada flair por 24 horas, então posts que você já viu aparecem na hora.
• Sem servidor externo, sem análise de uso, sem rastreamento. Só conversa com o www.reddit.com, com a sua sessão.

Código aberto (MIT): https://github.com/andremartinelli/reddit-feed-flair

Não oficial. Sem vínculo com o Reddit, Inc., nem aprovação dele.
```

### Privacy practices tab

**Single purpose:**

```
Show each post's flair on Reddit's Home, Popular, All and custom feeds, where Reddit hides it.
```

**Permission justification — storage:**

```
Caches each post's flair locally for 24 hours (up to 3,000 posts), so posts the user has already seen show their flair instantly without a new request to Reddit.
```

**Host permission justification — https://www.reddit.com/\* (content script):**

```
The extension only runs on www.reddit.com. It reads the posts on the feed, fetches each post's public data from www.reddit.com (/comments/<id>.json) and draws the flair badge next to the post.
```

**Remote code:** No, I am not using remote code.

**Data usage:** check none of the data types (decided 2026-11-23): nothing leaves the browser except the requests to www.reddit.com that the page itself makes. Check the three certifications (no selling, no unrelated use, no creditworthiness use).

**Privacy policy URL:**

```
https://github.com/andremartinelli/reddit-feed-flair/blob/main/PRIVACY.md
```

### Distribution tab

- Visibility: Public
- Regions: all
- Price: free

## Firefox Add-ons

Firefox settings live in `manifest.json` under `browser_specific_settings.gecko` (decided 2026-11-24): add-on ID `feed-flair@andremartinelli` (permanent), Firefox 140 or later, and data collection `none`, the same answer as in the Chrome Web Store.

**Distribution:** On this site (listed).

**Platforms:** Firefox only. Firefox for Android isn't tested.

**Source code:** No. The ZIP holds the source as written: no minifier, bundler or build step.

**Add-on URL:** `feed-flair-for-reddit`

**Summary:** `extDescription` from `_locales/en/messages.json`. For the Portuguese (Brazil) locale, the one from `_locales/pt_BR/messages.json`.

**Description:** the same texts as the Chrome Web Store, above.

**Experimental:** no. **Requires payment:** no.

**Categories:** Social & Communication. Second one, if asked: Appearance.

**Support email:** none.

**Support website:**

```
https://github.com/andremartinelli/reddit-feed-flair/issues
```

**Homepage:**

```
https://github.com/andremartinelli/reddit-feed-flair
```

**License:** The MIT License.

**Privacy policy:** the English part of `PRIVACY.md`, as plain text without the Markdown `##` headings and backticks.

**Notes to reviewer:** `store/amo-approval-notes.txt`. The "Publish to Firefox Add-ons" workflow sends it with every version. Never add a Reddit username or password: the extension works logged out.

**Release notes:** the text of the GitHub Release.

**Images:** the screenshot `store/screenshot-1280x800.png`. The icon comes from `manifest.json`. Firefox Add-ons doesn't use the promo tile.
