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

Tests use Ruby's Minitest framework. CI runs on Ruby 3.0 and 3.1 via GitHub Actions (`rake test` on push/PR).

## Architecture

### Core Utility
`scripts/update-host` is a 1056-line Perl script — the main entry point. It reads from `share/` and creates symlinks in the user's home directory. Supports `--tar` for tarball packaging and SSH-based remote sync.

### Config Layout
- `share/shell/` — `bashrc`, `bash_profile`, `inputrc`, SSH agent setup; `bashrc` supports per-host overrides via `.bashrc-$HOSTNAME` pattern
- `share/vim/` — Vim/GVim config (`vimrc`, `gvimrc`), skeleton templates, and custom plugins/syntax under `autoload/`, `plugin/`, `syntax/`, `after/`; nerdtree lives under `pack/vendor/start/` as a Git submodule
- `share/mutt/` — Mutt email client config
- `share/git-templates/` — Git hook templates

### Scripts (`scripts/`)
10 standalone scripts, pruned down from a much larger set of unused legacy utilities (2026-08-09):
- `git*` — Git workflow helpers (gitamend, gitbranchdelete, gitbranchrename, gitcheckout)
- `update-host` — main deploy/sync utility
- `claude-code-setup`, `signature`, `sync-upstream`, `open-terminals`, `make-admin` (Darwin-only)

### Tests (`test/`)
`test/scripts/skeleton_test.rb` — Minitest tests for the Vim skeleton module (skeleton file instantiation).

### Doc (`doc/`)
Code examples and educational snippets organized by language (C, C++, Perl, Python, Java, PHP, shell). These are reference material, not deployed code.

## Key Files

| File | Purpose |
|------|---------|
| `scripts/update-host` | Main deploy/sync script (Perl) |
| `share/shell/bashrc` | Primary shell config (543 lines) |
| `share/shell/bash_profile` | Login shell / PATH setup |
| `Rakefile` | Test and tar tasks |
| `Gemfile` | Ruby deps (minitest only) |
| `.gitmodules` | Vim plugin submodule (nerdtree) |
