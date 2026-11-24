#!/bin/sh
# Builds the store package (Chrome Web Store and Firefox Add-ons): dist/feed-flair-for-reddit-<version>.zip
set -e
cd "$(dirname "$0")"
version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' manifest.json)
out="dist/feed-flair-for-reddit-$version.zip"
mkdir -p dist
rm -f "$out"
zip -q -X "$out" manifest.json content.js style.css icons/*.png _locales/*/messages.json
echo "$out"
