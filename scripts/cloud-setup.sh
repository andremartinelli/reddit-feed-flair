#!/bin/bash
# Prepares a Claude Code cloud session (or any Linux box) to build and check
# the extension. Idempotent and non-interactive: installs only what is missing.
# The project has no dependencies, services, .env or migrations. It needs
# Node (syntax check), jq (JSON checks) and zip (build.sh), like CI.
# Never touches the Chrome Web Store: publishing runs only in GitHub Actions.
set -euo pipefail
cd "$(dirname "$0")/.."

missing=()
command -v jq >/dev/null 2>&1 || missing+=(jq)
command -v zip >/dev/null 2>&1 || missing+=(zip)

if [ ${#missing[@]} -gt 0 ]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo=""
    [ "$(id -u)" -eq 0 ] || sudo="sudo"
    echo "cloud-setup: installing ${missing[*]}"
    $sudo apt-get update -qq
    DEBIAN_FRONTEND=noninteractive $sudo apt-get install -y -qq "${missing[@]}" >/dev/null
  else
    echo "cloud-setup: missing ${missing[*]} and no apt-get; install them manually" >&2
    exit 1
  fi
fi

if ! command -v node >/dev/null 2>&1; then
  echo "cloud-setup: node not found; install Node 20+ (CI uses the one on ubuntu-latest)" >&2
  exit 1
fi

echo "cloud-setup: ready (node $(node --version), $(jq --version), zip $(zip -v | sed -n 2p | awk "{print \$4}"))"
