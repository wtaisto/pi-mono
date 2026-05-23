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

## Versioning convention

This fork uses `<next-upstream-patch>-fork.<N>` pre-release suffixes — e.g. if upstream's latest release is `0.75.5`, the next fork release is `0.75.6-fork.1`, then `0.75.6-fork.2`, etc. After a sync from upstream that brings in their `0.76.0`, the next fork release becomes `0.76.1-fork.1`.

**Why this scheme, not `<current-upstream>-fork.<N>`**: pi's built-in update notifier (`packages/coding-agent/src/utils/version-check.ts`) does semver-aware comparison against upstream's `https://pi.dev/api/latest-version`. Pre-release identifiers sort BELOW the plain version in semver, so `0.75.5-fork.1 < 0.75.5` — running a fork build with that version triggers a "0.75.5 is newer, run pi update" banner every launch. Using `0.75.6-fork.1` instead sorts as `0.75.5 < 0.75.6-fork.1 < 0.75.6`: the banner stays quiet until upstream actually ships something newer than the patch you're forked off, and when they do, you see it.

## Inputs

Ask the user for the suffix bump (almost always `1` for the first release after a sync, then incrementing). Determine the patch part automatically:

1. Read the current version from `packages/ai/package.json`.
2. If it already has a `-fork.<N>` suffix, the new version reuses the same `major.minor.patch` and bumps the suffix to `N+1` (you're rebuilding without a fresh sync).
3. If it's a plain `x.y.z` (just merged from upstream), the new version is `x.y.(z+1)-fork.1`.

The user can override with an explicit version — accept any valid semver greater than the current version. Reject inputs that would regress the update-checker comparison (e.g. dropping the `-fork.<N>` suffix entirely or using a suffix that sorts below the upstream release of the same patch).

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
