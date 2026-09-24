Sync the current git repo against every configured remote, then publish local
commits and tags. Runs `gitsync` (`scripts/gitsync` in this repo), which
`share/shell/bash_profile` puts on `PATH` via `$HOME/Applications/scripts`.

It is a bash script, so on Windows run it from Git Bash or WSL rather than
PowerShell or cmd.

## What it actually does

Read `scripts/gitsync` for the exact behavior, but note the asymmetry — the
fetching half loops, the publishing half does not:

- **For each remote**: `git pull <remote> <current-branch>`, then
  `git fetch --tags <remote>`, then `git remote prune <remote>`.
- **Once, after the loop**: a bare `git push` and `git push --tags`.

Those final two take no remote argument, so they go to the current branch's
upstream only. Syncing against three remotes does not publish to three
remotes. If the user expects a fan-out push, say so rather than letting them
assume it happened.

## Step 1: Confirm there's a repo here

```bash
git rev-parse --is-inside-work-tree
```

If this fails, tell the user there's no git repo in the current directory and
stop — don't search elsewhere for one.

## Step 2: Run it

```bash
gitsync
```

Run from the current working directory. It operates on whatever repo that is,
via `git remote`/`git branch` — there's nothing in it specific to this repo.

## Step 3: Report

Summarize what happened per remote: pulled clean / had conflicts / nothing to
pull, tags fetched, and whether the final `push`/`push --tags` succeeded, and
to which upstream. If a pull hit a merge conflict, stop and show it — don't
attempt to resolve it automatically. If a tag was rejected because it already
exists locally pointing at a different commit, say which tag and which remote
lost.
