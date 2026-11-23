// Feed Flair for Reddit
// Shows post flair in the lists where new Reddit hides it
// (Home, Popular, All, custom feeds). Where Reddit already shows it, does nothing.
(() => {
  'use strict';

  const TAG = '[Feed Flair for Reddit]';
  const DEBUG = false;        // true: diagnostic panel in the corner of the page
  const CONCURRENCY = 4;      // requests at the same time
  const GAP = 100;            // pause between request rounds (ms)
  const STORE_KEY = 'rffCache';
  const TTL = 24 * 60 * 60 * 1000; // keep each flair for 24 h
  const MAX_SAVED = 3000;
  const cache = new Map();    // t3_xxx -> flair | null (no flair)
  const savedAt = new Map();  // t3_xxx -> when it was fetched (successful results only)
  const links = new Map();    // t3_xxx -> permalink, for the fallback
  const queue = new Set();    // ids waiting to be fetched
  const stats = { json: '-', found: 0, fallback: 0, noTarget: 0, requests: 0, stored: 0 };
  let ready = false;
  let running = false;
  let timer = null;
  let saveTimer = null;

  // ---------- persist across reloads ----------

  async function loadCache() {
    try {
      const saved = (await chrome.storage.local.get(STORE_KEY))[STORE_KEY] || {};
      const now = Date.now();
      for (const [id, e] of Object.entries(saved)) {
        if (now - e.t < TTL) {
          cache.set(id, e.f);
          savedAt.set(id, e.t);
        }
      }
      stats.stored = savedAt.size;
    } catch (err) {
      console.warn(`${TAG} could not read the saved cache.`, err);
    }
  }

  function saveCacheSoon() {
    if (saveTimer) return;
    saveTimer = setTimeout(async () => {
      saveTimer = null;
      const newest = [...savedAt.entries()].sort((a, b) => b[1] - a[1]).slice(0, MAX_SAVED);
      const obj = {};
      for (const [id, t] of newest) obj[id] = { f: cache.get(id), t };
      try {
        await chrome.storage.local.set({ [STORE_KEY]: obj });
      } catch (err) {
        console.warn(`${TAG} could not save the cache.`, err);
      }
    }, 2000);
  }

  // ---------- find the posts ----------

  function fullnameOf(post) {
    const id = post.getAttribute('id') || '';
    if (/^t3_[a-z0-9]+$/i.test(id)) return id;
    const m = (post.getAttribute('permalink') || '').match(/\/comments\/([a-z0-9]+)/i);
    return m ? `t3_${m[1]}` : null;
  }

  // On the main feed Reddit puts an empty <shreddit-post-flair> in every post;
  // it only counts as Reddit's own flair if it has text or an emoji.
  function hasNativeFlair(post) {
    const nf = post.querySelector('shreddit-post-flair');
    return !!nf && (nf.textContent.trim() !== '' || !!nf.querySelector('img'));
  }

  function scan() {
    if (!ready) return;
    // The post's own page already shows the flair.
    if (/\/comments\//.test(location.pathname)) return;

    for (const post of document.querySelectorAll('shreddit-post')) {
      if (post.querySelector('.rff-flair') || hasNativeFlair(post)) continue;

      const name = fullnameOf(post);
      if (!name) continue;

      if (cache.has(name)) {
        const flair = cache.get(name);
        if (flair) render(post, flair);
        continue;
      }
      links.set(name, post.getAttribute('permalink'));
      queue.add(name);
    }
    if (queue.size && !running) flush();
    debugPanel();
  }

  // ---------- fetch the flairs ----------

  async function flush() {
    running = true;
    try {
      while (queue.size) {
        // Leave the queue only after the fetch, so a scan() during the fetch doesn't queue the post again.
        const names = [...queue].slice(0, CONCURRENCY);
        const results = await Promise.all(names.map(fetchFlair));
        const now = Date.now();
        names.forEach((n, i) => {
          queue.delete(n);
          // undefined = the fetch failed: kept in memory only, not saved.
          cache.set(n, results[i] ?? null);
          if (results[i] !== undefined) savedAt.set(n, now);
        });
        saveCacheSoon();
        scan(); // draw what arrived and pick up new posts from scrolling
        await sleep(GAP);
      }
    } finally {
      running = false;
    }
  }

  // Plan A: the post's JSON (/comments/<id>.json). The batch endpoints
  // (/api/info, /by_id) return 403 to the browser.
  async function fetchFlair(name) {
    const short = name.slice(3);
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        stats.requests += 1;
        const res = await fetch(`/comments/${short}.json?limit=1&raw_json=1`, {
          credentials: 'include',
        });
        if (res.status === 429 && attempt === 0) {
          stats.json = '429, waiting';
          await sleep(5000);
          continue;
        }
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const json = await res.json();
        const d = json?.[0]?.data?.children?.[0]?.data;
        if (!d) throw new Error('response without the post');
        stats.json = `ok ${res.status}`;
        const flair = fromApi(d);
        if (flair) stats.found += 1;
        return flair;
      } catch (err) {
        stats.json = `ERROR ${String(err).slice(0, 80)}`;
        console.warn(`${TAG} JSON for post ${name} failed, reading the post page.`, err);
        break;
      }
    }
    // Plan B: the post page.
    stats.fallback += 1;
    return fromPage(links.get(name));
  }

  function fromApi(d) {
    const rich = Array.isArray(d.link_flair_richtext) ? d.link_flair_richtext : [];
    const parts = rich.length
      ? rich.map((p) => (p.e === 'emoji' ? { emoji: p.u, alt: p.a } : { text: p.t || '' }))
      : d.link_flair_text
        ? [{ text: d.link_flair_text }]
        : [];
    if (!parts.some((p) => p.emoji || (p.text && p.text.trim()))) return null;
    return {
      parts,
      bg: d.link_flair_background_color || '',
      light: d.link_flair_text_color === 'light',
    };
  }

  // Returns the flair, null (post has no flair) or undefined (couldn't tell).
  async function fromPage(permalink) {
    if (!permalink) return undefined;
    try {
      const res = await fetch(permalink, { credentials: 'include' });
      if (!res.ok) return undefined;
      const doc = new DOMParser().parseFromString(await res.text(), 'text/html');
      const el =
        doc.querySelector('shreddit-post shreddit-post-flair .flair-content') ||
        doc.querySelector('shreddit-post-flair .flair-content');
      const text = el?.textContent.trim();
      return text ? { parts: [{ text }], bg: '', light: false } : null;
    } catch {
      return undefined;
    }
  }

  // ---------- draw ----------

  function render(post, flair) {
    // The "r/sub • 3 h" line is in an element with "credit-bar" in its id.
    const target =
      post.querySelector("[id*='credit-bar']") || post.querySelector('[slot="title"]');
    if (!target) {
      stats.noTarget += 1;
      return;
    }

    const badge = document.createElement('span');
    badge.className = 'rff-flair';
    if (flair.bg && flair.bg !== 'transparent') {
      badge.style.backgroundColor = flair.bg;
      badge.style.color = flair.light ? '#fff' : '#000';
    }
    for (const p of flair.parts) {
      if (p.emoji) {
        const img = document.createElement('img');
        img.className = 'rff-emoji';
        img.src = p.emoji;
        img.alt = p.alt || '';
        badge.append(img);
      } else if (p.text.trim()) {
        const span = document.createElement('span');
        span.className = 'rff-text';
        span.textContent = p.text.trim();
        badge.append(span);
      }
    }
    badge.title = badge.textContent.trim();
    target.append(badge);
  }

  // ---------- diagnostics ----------

  function debugPanel() {
    if (!DEBUG) return;
    let el = document.getElementById('rff-debug');
    if (!el) {
      el = document.createElement('pre');
      el.id = 'rff-debug';
      document.body.append(el);
    }
    const posts = document.querySelectorAll('shreddit-post').length;
    const text =
      `RFF debug | posts ${posts} | badges ${document.querySelectorAll('.rff-flair').length}` +
      ` | no flair ${[...cache.values()].filter((v) => v === null).length} | queue ${queue.size}\n` +
      `json ${stats.json} | requests ${stats.requests} | flairs ${stats.found}` +
      ` | fallback ${stats.fallback} | noTarget ${stats.noTarget} | stored ${stats.stored}`;
    // Only touch the panel when it changes, so the observer isn't woken for nothing.
    if (el.textContent !== text) el.textContent = text;
  }

  function sleep(ms) {
    return new Promise((r) => setTimeout(r, ms));
  }

  // ---------- follow scrolling and navigation ----------

  // At most one scan every 200 ms, even while Reddit keeps changing the page.
  new MutationObserver(() => {
    if (timer) return;
    timer = setTimeout(() => {
      timer = null;
      scan();
    }, 200);
  }).observe(document.documentElement, { childList: true, subtree: true });

  loadCache().then(() => {
    ready = true;
    scan();
  });
})();
