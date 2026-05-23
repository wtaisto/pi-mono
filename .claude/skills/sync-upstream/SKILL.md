---
name: sync-upstream
description: Merge upstream changes from earendil-works/pi into this fork (wtaisto/pi-mono) on a sync branch. Use when the user asks to sync upstream, pull upstream changes, update the fork, or merge from upstream.
---

# Sync from upstream

This fork (`wtaisto/pi-mono`, remote `origin`) tracks `earendil-works/pi` (remote `upstream`). This skill produces a merge of `upstream/main` into a fresh sync branch off `main`. It does NOT touch `main` directly and does NOT trigger a release — the user reviews and merges the branch themselves.

## Preconditions

Check ALL of these before doing anything. Surface the failing condition and stop:

1. CWD is the pi-mono repo root (`package.json` contains `"name": "pi-monorepo"`).
2. `git status --porcelain` is empty. If dirty, suggest `git stash` — do not stash silently.
3. `git remote get-url upstream` resolves to the earendil-works/pi repo. If the `upstream` remote is missing, suggest:
   ```
   git remote add upstream https://github.com/earendil-works/pi.git
   ```
   Do not add it silently.
4. Current branch is `main` (or the user has explicitly chosen a different base).

## Steps

1. **Fetch upstream**: `git fetch upstream --tags`.
2. **Show divergence in one block** before committing to the merge:
   - Count: `git rev-list --count main..upstream/main` (upstream commits to pull in).
   - Count: `git rev-list --count upstream/main..main` (local commits ahead — what's at risk if you mishandle conflicts).
   - Sample: `git log --oneline main..upstream/main | head -30`.
   - Sample: `git log --oneline upstream/main..main | head -20`.
   Print a one-line summary: `X upstream commits ahead, Y local commits ahead`. If X == 0, stop — nothing to sync.
3. **Create sync branch**: `git switch -c sync-upstream-YYYY-MM-DD`. If a branch with that name exists, suffix `-2`, `-3`, etc.
4. **Merge**: `git merge --no-ff upstream/main -m "Merge upstream/main into fork"`.
   - **On conflicts**: run `git status` to list conflicted paths, print them to the user, and STOP. Do not attempt to resolve — that needs human judgement on this fork's intent. Tell the user to resolve, `git add <files>`, `git merge --continue`, then re-run step 5 (the verification step) themselves or ask this skill to resume from verification.
5. **Verify the merge**:
   - If `package-lock.json` or any `package.json` changed in the merge, run `npm install`.
   - Run `npm run check` (biome + tsgo + browser smoke).
   - Run `npm test`.
   - On failure: report which step failed and stop. Do not push.
6. **Push the branch**: `git push -u origin <branch-name>`.
7. **Report**: tell the user the sync branch is pushed and suggest they either fast-forward `main` locally or open a PR. Do NOT merge to `main` automatically. Do NOT invoke the `release-fork` skill — releases are a separate, deliberate decision.

## Hard rules

- Never force-push.
- Never edit `main` directly in this skill.
- Never delete the `upstream` remote or reconfigure remotes silently.
- Never run `release-fork` from inside this skill.
