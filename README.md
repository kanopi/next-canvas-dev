# next-canvas-dev

Scripts and documentation for standing up a Drupal CMS site that consumes the [`drupal/ui`](https://www.drupal.org/project/ui) and [`kanopi/nextjs`](https://github.com/kanopi/nextjs) recipes, and pairing it with the [`kanopi/drupal-canvas-nextjs`](https://github.com/kanopi/drupal-canvas-nextjs) front end.

This repo contains **no Drupal site of its own** — running `bootstrap.sh` creates a fresh Drupal CMS install in a directory you pick (default: `~/Projects/canvas-test`). That mirrors exactly what a real consumer of the recipes would do, so the bootstrap doubles as an integration test.

## Prerequisites

- [DDEV](https://ddev.com/) ≥ 1.25 (Docker required)
- Node.js 20+ and `npm` (for the front end)
- `git`
- `~/Projects/drupal-canvas-nextjs/` cloned (or wherever you keep the front end)

## Default: consumer-style install

This is the recommended path. It tests the recipes the same way a stranger off the internet would consume them: standard Drupal CMS startup, then `composer require` our recipe via its published location.

```bash
git clone https://github.com/kanopi/next-canvas-dev.git ~/Projects/next-canvas-dev
cd ~/Projects/next-canvas-dev
./scripts/bootstrap.sh
```

What it does, step by step (following [the standard Drupal CMS startup](https://www.drupal.org/docs/drupal-cms/install)):

```bash
mkdir ~/Projects/canvas-test && cd ~/Projects/canvas-test
ddev config --project-type=drupal11 --docroot=web --project-name=canvas-test
ddev start
ddev composer create-project drupal/cms

# add Kanopi-hosted recipe + module (until they move to drupal.org)
ddev composer config repositories.kanopi-nextjs      vcs https://github.com/kanopi/nextjs
ddev composer config repositories.kanopi-next_canvas vcs https://github.com/kanopi/next_canvas

# pull in our recipe (transitively pulls drupal/ui from drupal.org)
ddev composer require kanopi/nextjs

# apply the recipe
ddev drush recipe recipes/contrib/nextjs -y

# generate Simple OAuth keys for Canvas CLI
ddev exec mkdir -p /var/www/html/keys
ddev drush simple-oauth:generate-keys /var/www/html/keys
ddev drush config:set simple_oauth.settings public_key  /var/www/html/keys/public.key  -y
ddev drush config:set simple_oauth.settings private_key /var/www/html/keys/private.key -y
```

Drupal CMS is up at `https://canvas-test.ddev.site`. Use `ddev drush uli` to grab a one-time admin login.

### Then the front end

```bash
cd ~/Projects/drupal-canvas-nextjs
echo 'NEXT_PUBLIC_DRUPAL_BASE_URL=https://canvas-test.ddev.site' >  .env.local
echo 'CANVAS_SITE_URL=https://canvas-test.ddev.site'             >> .env.local
npm install
npm run dev
```

Open `http://localhost:3000`. Or just run `./scripts/sync-front-end.sh` from this repo and skip the manual env / install steps.

## Dev mode: composer path repositories

Use this when you're actively editing the recipes / module and want changes to flow in without a publish step. Requires sibling clones of `ui`, `nextjs`, and `next_canvas`.

```bash
cd ~/Projects   # so siblings live here
git clone https://git.drupalcode.org/project/ui.git
git clone https://github.com/kanopi/nextjs.git
git clone https://github.com/kanopi/next_canvas.git

cd ~/Projects/next-canvas-dev
./scripts/bootstrap.sh --siblings
```

The `--siblings` flag swaps the VCS repositories for path repositories pointing at `../ui`, `../nextjs`, `../next_canvas`, and adds a docker-compose override that mounts the host paths into the DDEV web container. Edits in any of the sibling clones are visible to the running Drupal site immediately. Re-apply with:

```bash
cd ~/Projects/canvas-test
ddev drush recipe recipes/contrib/nextjs -y
```

## Daily dev loop (with siblings)

```bash
# Edit a Canvas component
cd ~/Projects/drupal-canvas-nextjs
$EDITOR src/components/canvas/button/index.tsx

# Push to the dev Drupal
npx canvas push --site-url https://canvas-test.ddev.site

# Sync the resulting config back into the ui recipe checkout
npm run canvas:sync-recipe -- --recipe-path ~/Projects/ui

# Review and commit in each repo that has changes
cd ~/Projects/drupal-canvas-nextjs && git status
cd ~/Projects/ui && git status
```

## Stopping and restarting

```bash
# Stop everything
cd ~/Projects/canvas-test && ddev stop
# Ctrl+C in the npm run dev terminal

# Bring it back up later
cd ~/Projects/canvas-test && ddev start
cd ~/Projects/drupal-canvas-nextjs && npm run dev
```

## Tearing down completely

```bash
cd ~/Projects/canvas-test
ddev delete canvas-test -O   # removes containers + database
cd ..
rm -rf canvas-test           # removes the Drupal install
# Sibling clones (ui, nextjs, next_canvas, drupal-canvas-nextjs) untouched
```

`./scripts/bootstrap.sh` will rebuild from scratch.

## Why this repo exists

The four production repos (`drupal-canvas-nextjs`, `ui`, `nextjs`, `next_canvas`) are intentionally minimal — each ships only what it owns, none of them carries a Drupal site or DDEV config. This repo is the small launcher that wires them together for dev and verification work.

## Related repos

| | |
|---|---|
| [`kanopi/drupal-canvas-nextjs`](https://github.com/kanopi/drupal-canvas-nextjs) | Next.js front end |
| [`drupal/ui`](https://www.drupal.org/project/ui) | UI recipe |
| [`kanopi/nextjs`](https://github.com/kanopi/nextjs) | NextJS site template recipe |
| [`kanopi/next_canvas`](https://github.com/kanopi/next_canvas) | Decoupled bridge module |

## License

GPL-2.0-or-later.
