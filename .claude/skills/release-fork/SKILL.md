---
name: release-fork
description: Cut a release of this fork (wtaisto/pi-mono). Bumps versions, updates changelogs, tags, and pushes — CI then builds binaries and publishes a GitHub Release. Use when the user asks to release, tag, cut a version, or publish a new build of the fork.
---

# Release the fork

`scripts/release.mjs` was written for the upstream maintainers and calls `npm run publish`, which tries to publish to the `@mariozechner/*` npm scope. This fork doesn't own that scope, so running `release.mjs` would abort mid-release. This skill performs the fork-only flow:

> bump versions → update changelogs → commit → tag → push → CI builds binaries → GitHub Release

The `install.sh` / `install.ps1` at the repo root point at whatever Release the workflow produces, so a successful tag push is what makes the installers serve a new version.

## Preconditions

Stop on any failure:

1. CWD is the pi-mono repo root.
2. `git status --porcelain` is empty.
3. Current branch is `main`.
4. `git fetch origin` then `git rev-list main..origin/main` is empty (local main is up to date with the remote).

## Inputs

Ask the user for the bump kind unless they already specified one. Accept:
- `patch` | `minor` | `major`
- Or an explicit `x.y.z` greater than the current version.

The canonical "current version" is whatever is in `packages/ai/package.json` (this matches what `scripts/release.mjs` uses).

## Steps

1. **Bump versions across the workspace**.
   - For `patch` / `minor` / `major`: `npm run version:<kind>`. This is a single existing script that runs `npm version <kind> -ws --no-git-tag-version`, then `sync-versions.js`, then refreshes `node_modules` + `package-lock.json`.
   - For an explicit version: run the same command sequence inline with `npm version <x.y.z> -ws --no-git-tag-version && node scripts/sync-versions.js && npx shx rm -rf node_modules packages/*/node_modules package-lock.json && npm install`.
   - Read the new version from `packages/ai/package.json` afterwards.
2. **Update changelogs**. For each `packages/*/CHANGELOG.md` that contains `## [Unreleased]`, replace exactly that heading with `## [<version>] - <YYYY-MM-DD>` (today's date). Leave changelogs without an `[Unreleased]` section untouched.
3. **Sanity check (optional but recommended)**: `npm run check && npm test`. If either fails, abort — do not commit or tag. The pushed tag triggers a long binary build job; failing CI on a tag leaves a broken release lying around.
4. **Commit and tag**:
   - `git add -A` (broad change set: every workspace package.json + lockfile + changelogs).
   - `git commit -m "Release v<version>"`.
   - `git tag v<version>`.
5. **Push**:
   - `git push origin main`
   - `git push origin v<version>` (this is what fires `.github/workflows/build-binaries.yml`).
6. **Re-add `[Unreleased]` sections** to each touched changelog (insert `## [Unreleased]\n\n` immediately after the `# Changelog\n\n` header). Commit as `Add [Unreleased] section for next cycle` and push to `main`.
7. **Report** the tag, the workflow URL (`https://github.com/wtaisto/pi-mono/actions/workflows/build-binaries.yml`), and the eventual release URL (`https://github.com/wtaisto/pi-mono/releases/tag/v<version>`). Tell the user the GitHub Release will appear once the workflow finishes (a few minutes).

## What this skill explicitly does NOT do

- Does not run `npm publish` or `scripts/release.mjs`. Both attempt npm-scope publishing the fork can't do.
- Does not create the GitHub Release directly — CI does it via `build-binaries.yml`. If CI fails on the tag, fix the workflow rather than uploading binaries by hand.
- Does not delete or move existing tags. Re-tagging is destructive; if the user asks, confirm explicitly before `git tag -d` + `git push origin :refs/tags/...`.
