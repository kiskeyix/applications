Audit our tracked Claude Code settings against the changelog after a version
upgrade. Triggered manually, or automatically by
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
# ~/.claude/hooks is a symlink into the Applications repo's share/claude/hooks
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

Only if both fetches in steps 2–3 actually succeeded (regardless of
whether they found anything to fix), record that this version was reviewed:

```bash
echo "$installed" > "$config_dir/.claude-code-verified-version"
```

If a fetch failed, don't stamp — leave the SessionStart nudge active so the
next session retries.

## Step 6: Report

One concise summary: version jump reviewed, what (if anything) was found, what
was fixed vs. what's waiting on confirmation, and whether the stamp was
updated.
