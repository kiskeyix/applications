# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- `share/claude/hooks/` — Claude Code hooks (`session-start.sh`, `notify-stop.sh`, `check-claude-version.sh`), symlinked to `~/.claude/hooks` by `update-host`; `share/claude/commands/` — custom slash commands (`claude-update-check.md`), symlinked to `~/.claude/commands`; `share/claude/CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md` the same way — general, cross-project working principles, not project-specific facts (those stay in a repo's own `CLAUDE.md`). `share/claude/settings.json.example` is merged (not symlinked) into `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR/settings.json`) since Claude Code writes into that file at runtime. The repo's own `.claude/hooks`, `.claude/commands`, `.claude/CLAUDE.md`, and `.claude/settings.json.example` are symlinks back into `share/claude/`, so this repo picks up the same hooks and commands when Claude Code works on itself.

### Scripts (`scripts/`)
10 standalone scripts, pruned down from a much larger set of unused legacy utilities (2026-08-09):
- `git*` — Git workflow helpers (gitamend, gitbranchdelete, gitbranchrename, gitcheckout, gitsync)
- `update-host` — main deploy/sync utility
- `claude-code-setup`, `signature`, `open-terminals`, `make-admin` (Darwin-only)

### Tests (`test/`)
- `test/scripts/skeleton_test.rb` — Vim skeleton module (skeleton file instantiation)
- `test/scripts/update_host_test.rb` — `update-host`'s dotfile path mapping and Claude settings deep-merge
- `test/scripts/claude_code_setup_test.rb` — `claude-code-setup`'s platform detection, package-manager command builders, and settings deep-merge

### Doc (`doc/`)
Code examples and educational snippets organized by language (C, C++, Perl, Python, Java, PHP, shell). These are reference material, not deployed code.

## Key Files

| File | Purpose |
|------|---------|
| `scripts/update-host` | Main deploy/sync script (Ruby) |
| `share/shell/bashrc` | Primary shell config (543 lines) |
| `share/shell/bash_profile` | Login shell / PATH setup |
| `Rakefile` | Test and tar tasks |
| `Gemfile` | Ruby deps (minitest only) |
| `.gitmodules` | Vim plugin submodule (nerdtree) |
