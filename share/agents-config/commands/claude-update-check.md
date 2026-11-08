Audit our tracked Claude Code settings against the changelog and a local
binary diff after a version upgrade. Triggered manually, or automatically by
`~/.claude/hooks/check-claude-version.sh`'s SessionStart nudge when the
installed `claude --version` differs from the last-verified stamp.

Context: a settings value that looks plausible but isn't documented fails
silently (e.g. `attribution.commit: "hide"` — the documented way to hide
attribution is an empty string `""`). This command exists to catch that kind
of drift against the docs, not from memory.

## Step 1: Locate files and compare versions

```bash
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
live="$config_dir/settings.json"
# ~/.claude/hooks is a symlink into the Applications repo's share/agents-config/hooks
template="$(dirname "$(readlink -f "$config_dir/hooks")")/settings.json.example"
installed=$(claude --version | awk '{print $1}')
verified=$(cat "$config_dir/.claude-code-verified-version" 2>/dev/null || echo "")
```

If `$installed == $verified`, report "Claude Code $installed already verified,
nothing to do" and stop here.

## Step 2: Fetch the changelog

`WebFetch` `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`.
If that fails (network/proxy), fall back to
`https://docs.claude.com/en/release-notes/claude-code`.

Ask it to extract entries **between `$verified` (exclusive) and `$installed`
(inclusive)** that mention: settings/config keys, `settings.json`,
permissions, hooks, attribution/co-authored-by, MCP config, CLI flags, or any
"breaking"/"deprecated" language.

If `$verified` is empty (never checked before), there's no lower bound — default
to the most recent ~15 entries and say so explicitly in the report (we're not
diffing full history).

## Step 2b: Diff the binaries

The changelog can lag a release (2.1.319 reached the native installer before
its changelog entry existed), so also diff the binaries locally. The native
installer keeps recent versions in `~/.local/share/claude/versions/`:

```bash
versions="$HOME/.local/share/claude/versions"
claude-binary-diff "$versions/$verified" "$versions/$installed" "$live" "$template"
```

`claude-binary-diff` lives in the Applications repo's `scripts/` (on `PATH`)
and takes ~10s. It reports:
- env vars (`CLAUDE_*`/`ANTHROPIC_*`) added or removed;
- settings-schema keys added, removed, or re-described — best effort: it only
  matches keys declared as `key:()=>…describe(…)` (about half the schema), so
  a key absent from that list isn't proof of removal;
- keys set in `$live`/`$template` that no longer appear anywhere in the new
  binary — a strong sign of a removal or rename; confirm each in step 3.

For each added env var or schema key, grep the settings reference downloaded
in step 3 and note whether it's documented yet. That part is informational:
report it, don't act on it unless it touches a key we set.

If `$versions/$verified` is gone (the installer prunes old versions) or
`$verified` is empty, diff from the oldest version still in `$versions` and
say which. With no `$versions` dir (an npm install), skip this step and say so.

## Step 3: Check settings-reference for drift

Download `https://code.claude.com/docs/en/settings-reference.md` with `curl`
and `grep` it per key — the page is ~6000 lines, too long for a WebFetch
summary to quote reliably. Check every key currently set in:
- `$live` — the real global settings file (primary target)
- `$template` — the tracked template `update-host` merges into `$live`

Flag any key that's deprecated, renamed, or whose current value doesn't match
the documented type/enum for that key. Quote the doc line for each finding.

## Step 4: Fix the template, ask before touching the live file

For each confirmed finding:
- **`$template`**: edit it directly (git-tracked, reversible). Show the diff.
  Don't commit or push — ask the user first.
- **`$live`**: don't edit automatically. Report the proposed change and ask
  before writing it.

If nothing was found, say so plainly — don't manufacture a finding.

## Step 5: Stamp the version

Only if step 3's download succeeded and the changes up to `$installed` were
actually reviewed — by a changelog entry for `$installed` (step 2) or by the
binary diff (step 2b) — record that this version was reviewed, regardless of
whether anything needed fixing:

```bash
echo "$installed" > "$config_dir/.claude-code-verified-version"
```

Otherwise don't stamp — leave the SessionStart nudge active so the next
session retries.

## Step 6: Report

One concise summary: version jump reviewed, binary-diff highlights, what (if
anything) was found, what was fixed vs. what's waiting on confirmation, and
whether the stamp was updated.
