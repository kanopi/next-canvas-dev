#!/usr/bin/env bash
#
# sync-front-end.sh — convenience wrapper that boots the front end pointed
# at this DDEV site.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONT_END="$PARENT_DIR/drupal-canvas-nextjs"

[[ ! -d "$FRONT_END" ]] && { echo "Error: $FRONT_END not found. Run bootstrap.sh first."; exit 1; }

cd "$FRONT_END"
[[ ! -f .env.local ]] && cp .env.example .env.local
[[ ! -d node_modules ]] && npm install

NEXT_PUBLIC_DRUPAL_BASE_URL=https://next-canvas-dev.ddev.site \
CANVAS_SITE_URL=https://next-canvas-dev.ddev.site \
  npm run dev
