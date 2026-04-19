#!/usr/bin/env bash
# Regenerate native/bundle/quicktype_bundle.js from shim.mjs.
#
# Prereqs: npm installed, ran `npm install` in this directory first.
#
# After this, regenerate the C embed:
#   python3 ../shim/embed_bundle.py prelude.js quicktype_bundle.js ../shim/bundle_data.c

set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d node_modules ]; then
  echo "error: node_modules not found. Run 'npm install' here first." >&2
  exit 1
fi

npx esbuild shim.mjs \
  --bundle \
  --platform=browser \
  --format=iife \
  --outfile=quicktype_bundle.js \
  --log-level=warning \
  --alias:node:fs=./empty.cjs \
  --alias:node:process=./empty.cjs \
  --alias:node:path=./empty.cjs \
  --alias:node:stream=./empty.cjs \
  --alias:node:child_process=./empty.cjs \
  --alias:node:url=./empty.cjs \
  --alias:node:buffer=./empty.cjs \
  --alias:node:events=./empty.cjs

ls -lh quicktype_bundle.js
