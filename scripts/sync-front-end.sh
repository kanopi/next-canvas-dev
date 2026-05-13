#!/usr/bin/env bash
#
# sync-front-end.sh — runs the front end pointed at a Drupal CMS site
# you created via bootstrap.sh.
#
# Usage:
#   ./scripts/sync-front-end.sh                       # uses ~/Projects/canvas-test
#   ./scripts/sync-front-end.sh --target PATH         # uses Drupal site at PATH
#   ./scripts/sync-front-end.sh --front-end PATH      # path to drupal-canvas-nextjs
#
set -euo pipefail

TARGET="$HOME/Projects/canvas-test"
FRONT_END=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --front-end) FRONT_END="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--target PATH] [--front-end PATH]"
      exit 1 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$FRONT_END" ]]; then
  # Default: sibling of the Drupal site.
  FRONT_END="$(dirname "$TARGET")/drupal-canvas-nextjs"
fi

[[ ! -d "$FRONT_END" ]] && { echo "Error: front-end repo not found at $FRONT_END"; exit 1; }
[[ ! -d "$TARGET/.ddev" ]] && { echo "Error: no Drupal site at $TARGET. Run bootstrap.sh first."; exit 1; }

DDEV_NAME="$(basename "$TARGET")"
BASE_URL="https://${DDEV_NAME}.ddev.site"

cd "$FRONT_END"
[[ ! -f .env.local ]] && {
  echo "NEXT_PUBLIC_DRUPAL_BASE_URL=$BASE_URL" >  .env.local
  echo "CANVAS_SITE_URL=$BASE_URL"             >> .env.local
}
[[ ! -d node_modules ]] && npm install

NEXT_PUBLIC_DRUPAL_BASE_URL="$BASE_URL" CANVAS_SITE_URL="$BASE_URL" npm run dev
