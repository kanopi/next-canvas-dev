# next-canvas-dev

A local Drupal + DDEV environment that wires together the four split repos behind [`drupal-canvas-nextjs`](https://github.com/kanopi/drupal-canvas-nextjs). Use this when you need to verify the full stack — recipe + module + front end — works end-to-end.

This repo is the **integration sandbox**, not a production template. It pulls the other four packages in via composer **path repositories** so any edit you make in a sibling clone shows up here immediately, no publish step required.

## Expected layout on disk

```
~/Projects/
  drupal-canvas-nextjs/   ← Next.js front end
  ui/                     ← drupal/ui recipe
  nextjs/                 ← kanopi/nextjs recipe
  next_canvas/            ← kanopi/next_canvas module
  next-canvas-dev/        ← THIS repo
```

The `scripts/bootstrap.sh` script clones any missing siblings into `../` and brings everything up.

## First-time bootstrap

```bash
git clone https://github.com/kanopi/next-canvas-dev ~/Projects/next-canvas-dev
cd ~/Projects/next-canvas-dev
./scripts/bootstrap.sh
```

This will:

1. Clone the four sibling repos into `../` if they aren't already there.
2. `ddev start` (project name: `next-canvas-dev`).
3. `ddev composer install` — resolves the recipes + module from the sibling path repos.
4. Apply the `nextjs` recipe (which transitively applies `ui` and enables `next_canvas`).
5. Generate Simple OAuth keys for Canvas CLI auth.

After bootstrap, Drupal is at `https://next-canvas-dev.ddev.site`.

## Run the front end

```bash
./scripts/sync-front-end.sh
```

This copies `.env.example` → `.env.local`, runs `npm install` if needed, then `npm run dev` with `NEXT_PUBLIC_DRUPAL_BASE_URL` pointed at this DDEV site. Front end at `http://localhost:3000`.

## Daily development loop

```bash
# Edit a component in the front end repo
cd ~/Projects/drupal-canvas-nextjs
$EDITOR src/components/canvas/button/index.tsx

# Push to Drupal
npx canvas push --site-url https://next-canvas-dev.ddev.site

# Sync the resulting config back into the ui recipe checkout
npm run canvas:sync-recipe -- --recipe-path ../ui

# Review and commit in each repo that has changes
cd ~/Projects/drupal-canvas-nextjs && git status
cd ~/Projects/ui && git status
```

Because everything is path-repo'd, changes in `../ui` reapply instantly via `ddev drush recipe recipes/contrib/ui -y` — no composer reinstall needed.

## Why a separate dev repo?

The four production repos (`drupal-canvas-nextjs`, `ui`, `nextjs`, `next_canvas`) are intentionally minimal: each ships only what it owns. None of them carries a Drupal site, a DDEV config, or composer scaffolding. That makes them small, fast to clone, and easy to publish.

This repo provides the working Drupal install needed to actually run them together. It carries the DDEV config, the composer scaffold, and the bootstrap automation. It is the answer to "how do I develop on the stack."

## Tearing down

```bash
ddev delete next-canvas-dev -O
rm -rf web/ vendor/ composer.lock
```

A re-run of `./scripts/bootstrap.sh` rebuilds from scratch.

## License

GPL-2.0-or-later.
