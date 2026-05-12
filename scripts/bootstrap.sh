#!/usr/bin/env bash
#
# bootstrap.sh — first-time setup of the next-canvas-dev integration sandbox.
#
# Expects sibling clones in ../:
#   ../drupal-canvas-nextjs   (front end)
#   ../ui                     (UI recipe)
#   ../nextjs                 (NextJS recipe)
#   ../next_canvas            (decoupled bridge module)
#
# Clones any missing siblings, brings up DDEV, runs composer install,
# applies the nextjs recipe, then prints next steps for the front end.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PARENT_DIR="$(cd "$ROOT_DIR/.." && pwd)"

declare -A SIBLINGS=(
  [drupal-canvas-nextjs]="https://github.com/kanopi/drupal-canvas-nextjs.git"
  [ui]="https://git.drupalcode.org/project/ui.git"
  [nextjs]="https://github.com/kanopi/nextjs.git"
  [next_canvas]="https://github.com/kanopi/next_canvas.git"
)

echo "==> Checking sibling repos in $PARENT_DIR"
for name in "${!SIBLINGS[@]}"; do
  path="$PARENT_DIR/$name"
  if [[ -d "$path/.git" ]]; then
    echo "    found: $name"
  else
    echo "    cloning: $name <- ${SIBLINGS[$name]}"
    git clone "${SIBLINGS[$name]}" "$path"
  fi
done

cd "$ROOT_DIR"

echo "==> Starting DDEV"
ddev start

echo "==> Running composer install"
ddev composer install --no-interaction

echo "==> Applying nextjs recipe"
ddev drush site:install --account-name=admin --account-pass=admin -y minimal --existing-config=false
ddev drush recipe recipes/contrib/nextjs -y

echo "==> Generating OAuth keys for Simple OAuth + Canvas CLI"
ddev exec mkdir -p /var/www/html/keys
ddev drush simple-oauth:generate-keys /var/www/html/keys
ddev drush config:set simple_oauth.settings public_key /var/www/html/keys/public.key -y
ddev drush config:set simple_oauth.settings private_key /var/www/html/keys/private.key -y

echo
echo "Drupal is up at: https://next-canvas-dev.ddev.site"
echo
echo "Next steps (front end):"
echo "  cd $PARENT_DIR/drupal-canvas-nextjs"
echo "  cp .env.example .env.local"
echo "  npm install"
echo "  npm run dev"
