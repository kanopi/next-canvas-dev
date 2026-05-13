#!/usr/bin/env bash
#
# bootstrap.sh — stand up a Drupal CMS site that consumes our published
# recipes, mirroring exactly what a real user would do.
#
# Flow:
#   1. mkdir target site dir + cd into it
#   2. ddev config --project-type=drupal11 --docroot=web
#   3. ddev composer create-project drupal/cms     (the standard d.o startup)
#   4. composer config repositories.* vcs https://github.com/kanopi/{nextjs,next_canvas}
#   5. ddev composer require kanopi/nextjs          (pulls drupal/ui transitively)
#   6. ddev drush recipe recipes/contrib/nextjs -y
#   7. Generate Simple OAuth keys
#
# Result: a Drupal CMS site at https://<name>.ddev.site rendering the
# shadcn/ui Canvas Code Components, ready for the Next.js front end to
# consume. The site is in <target-dir>; this repo only holds the script
# and docs.
#
# Usage:
#   ./scripts/bootstrap.sh                    # creates ~/Projects/canvas-test
#   ./scripts/bootstrap.sh --target PATH      # creates a site at PATH
#   ./scripts/bootstrap.sh --target PATH --siblings   # uses ../ui ../nextjs ../next_canvas
#                                                       as composer path overrides instead of
#                                                       VCS — for active recipe development
#
set -euo pipefail

TARGET="$HOME/Projects/canvas-test"
USE_SIBLINGS=false

usage() {
  cat <<USAGE
Usage: $0 [--target PATH] [--siblings]

Options:
  --target PATH    Directory to create the Drupal CMS site in.
                   Default: ~/Projects/canvas-test
  --siblings       Use composer path repositories pointing at
                   ../ui, ../nextjs, ../next_canvas instead of the
                   published Kanopi GitHub VCS repos. For local recipe
                   development; requires those clones to exist as
                   siblings of TARGET.
  -h, --help       Show this help.
USAGE
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --siblings) USE_SIBLINGS=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

if [[ -d "$TARGET" ]]; then
  echo "Error: $TARGET already exists. Remove it or pass --target to use a different path."
  exit 1
fi

DDEV_NAME="$(basename "$TARGET")"

echo "==> Creating Drupal CMS site at: $TARGET"
mkdir -p "$TARGET"
cd "$TARGET"

echo "==> Configuring DDEV (project name: $DDEV_NAME, drupal11, docroot=web)"
ddev config --project-type=drupal11 --docroot=web --project-name="$DDEV_NAME"

echo "==> Starting DDEV"
ddev start

echo "==> Creating Drupal CMS project (this may take a few minutes)"
ddev composer create-project drupal/cms

if [[ "$USE_SIBLINGS" == "true" ]]; then
  PARENT="$(cd "$(dirname "$TARGET")" && pwd)"
  for sib in ui nextjs next_canvas; do
    if [[ ! -d "$PARENT/$sib/.git" ]]; then
      echo "Error: --siblings requires $PARENT/$sib to exist. Clone the sibling repos first."
      exit 1
    fi
  done

  echo "==> Wiring composer path repositories to siblings in $PARENT"
  ddev composer config repositories.dev-ui          path ../ui
  ddev composer config repositories.dev-nextjs      path ../nextjs
  ddev composer config repositories.dev-next-canvas path ../next_canvas
  # The path mounts need to be visible inside the container.
  cat > .ddev/docker-compose.siblings.yaml <<COMPOSE
services:
  web:
    volumes:
      - "$PARENT/ui:/var/www/ui:cached"
      - "$PARENT/nextjs:/var/www/nextjs:cached"
      - "$PARENT/next_canvas:/var/www/next_canvas:cached"
COMPOSE
  ddev restart
else
  echo "==> Wiring composer VCS repositories for Kanopi-hosted packages"
  ddev composer config repositories.kanopi-nextjs      vcs https://github.com/kanopi/nextjs
  ddev composer config repositories.kanopi-next_canvas vcs https://github.com/kanopi/next_canvas
fi

echo "==> Requiring kanopi/nextjs (this pulls drupal/ui and kanopi/next_canvas transitively)"
ddev composer require kanopi/nextjs

echo "==> Applying the nextjs recipe"
ddev drush recipe recipes/contrib/nextjs -y

echo "==> Generating Simple OAuth keys"
ddev exec mkdir -p /var/www/html/keys
ddev drush simple-oauth:generate-keys /var/www/html/keys
ddev drush config:set simple_oauth.settings public_key /var/www/html/keys/public.key -y
ddev drush config:set simple_oauth.settings private_key /var/www/html/keys/private.key -y

echo
echo "==============================================================="
echo "Drupal CMS site: https://$DDEV_NAME.ddev.site"
echo "Admin URL:       https://$DDEV_NAME.ddev.site/user/login"
echo
echo "Now wire up the front end:"
echo "  cd ~/Projects/drupal-canvas-nextjs"
echo "  echo 'NEXT_PUBLIC_DRUPAL_BASE_URL=https://$DDEV_NAME.ddev.site' > .env.local"
echo "  echo 'CANVAS_SITE_URL=https://$DDEV_NAME.ddev.site'          >> .env.local"
echo "  npm install"
echo "  npm run dev"
echo "==============================================================="
