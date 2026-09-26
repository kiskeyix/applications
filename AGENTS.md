# AGENTS.md

This file provides guidance to coding agents working in this repository.

## What This Repo Is

A personal Unix/Linux dotfiles and configuration management system. The core utility (`scripts/update-host`) deploys shell, vim, mutt, and other configs from this repo to a home directory via symlinks, and can sync configs to remote hosts over SSH.

## Commands

```bash
# Run test suite
bundle exec rake test

# Run rake directly (default task is test)
rake

# Build tarball for distribution
rake tar
```

Tests use Ruby's Minitest framework. CI runs on Ruby 4.0 and 3.4 via GitHub Actions (`rake test` on push/PR).

## Architecture

### Core Utility
`scripts/update-host` is a Ruby script — the main entry point. `update-host --local` symlinks `share/` configs into the user's home directory; `update-host [HOST...]` (or no args, reading `~/.remote-hosts`) builds a tarball, ships it to each host in parallel over SSH/SCP with a live progress bar, and relinks configs there too. `--tar` builds the tarball only; `--send-key` pushes your SSH pubkey to hosts; `--verify` is the read-only counterpart to `--local` — it reports whether a machine already matches what `--local` would produce (symlinks, merged Claude settings, hook executability, git-templates wiring, the vim submodule, supporting paths) without changing anything, exiting non-zero only when a check reports a concrete fix (warnings are advisory and don't fail the run).

### Config Layout
- `share/shell/` — `bashrc`, `bash_profile`, `inputrc`, SSH agent setup; `bashrc` supports per-host overrides via `.bashrc-$HOSTNAME` pattern
- `share/vim/` — Vim/GVim config (`vimrc`, `gvimrc`), skeleton templates, and custom plugins/syntax under `autoload/`, `plugin/`, `syntax/`, `after/`; nerdtree lives under `pack/vendor/start/` as a Git submodule
- `share/mutt/` — Mutt email client config
- `share/git-templates/` — Git hook templates
- `share/claude/hooks/` — Claude Code hooks (`session-start.sh`, `notify-stop.sh`, `check-claude-version.sh`), symlinked to `~/.claude/hooks` by `update-host`; `share/claude/commands/` — custom slash commands (`claude-update-check.md`), symlinked to `~/.claude/commands`; `share/claude/AGENTS.md` is symlinked to `~/.claude/AGENTS.md` the same way — general, cross-project working principles, not project-specific facts (those stay in a repo's own `AGENTS.md`). Claude Code's built-in "agents-md" plugin (on by default as of 2.1.283, mode `claude-md-or-agents-md`) loads an `AGENTS.md` exactly where a `CLAUDE.md` would be loaded — but only when no `CLAUDE.md`-family file (`CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md`) exists anywhere from the working directory up to `$HOME`; any such file anywhere in that chain suppresses AGENTS.md loading entirely, so `update-host --local`/`--verify` retire a stale `~/.claude/CLAUDE.md` symlink to keep it from shadowing `~/.claude/AGENTS.md`. `share/claude/settings.json.example` is merged (not symlinked) into `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR/settings.json`) since Claude Code writes into that file at runtime. The repo's own `.claude/hooks` and `.claude/commands` are symlinks back into `share/claude/`, so this repo picks up the same hooks and commands when Claude Code works on itself; it has no `.claude/AGENTS.md` of its own since the root-level `AGENTS.md` above already covers this repo.

### Scripts (`scripts/`)
Standalone scripts:
- `git*` — Git workflow helpers (gitamend, gitbranchdelete, gitbranchrename, gitcheckout, gitsync)
- `update-host` — main deploy/sync utility
- `claude-code-setup`, `signature`, `open-terminals`, `make-admin` (Darwin-only)

### Tests (`test/`)
- `test/scripts/skeleton_test.rb` — Vim skeleton module (skeleton file instantiation)
- `test/scripts/update_host_test.rb` — `update-host`'s dotfile path mapping, Claude settings deep-merge, `--verify` checks, and stale `~/.claude/CLAUDE.md` cleanup
- `test/scripts/claude_code_setup_test.rb` — `claude-code-setup`'s platform detection, package-manager command builders, and settings deep-merge

### Doc (`doc/`)
Code examples and educational snippets organized by language (C, C++, Perl, Python, Java, PHP, shell). These are reference material, not deployed code.

## Key Files

| File | Purpose |
|------|---------|
| `scripts/update-host` | Main deploy/sync script (Ruby) |
| `share/shell/bashrc` | Primary shell config |
| `share/shell/bash_profile` | Login shell / PATH setup |
| `Rakefile` | Test and tar tasks |
| `Gemfile` | Ruby deps (minitest only) |
| `.gitmodules` | Vim plugin submodule (nerdtree) |
