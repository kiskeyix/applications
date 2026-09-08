Audit our tracked Claude Code settings against the changelog after a version
upgrade. Triggered manually, or automatically by
`.claude/hooks/check-claude-version.sh`'s SessionStart nudge when the
installed `claude --version` differs from the last-verified stamp.

Context: Claude Code 2.1.247 shipped with `.claude/settings.json.example`
carrying `"attribution": {"commit": "", "pr": ""}` — plausible-looking but
invalid (the real value is the string `"hide"`), so it silently did nothing
and attribution stayed on. That bug motivated this command: catch the next
one before it's discovered by accident.

## Step 1: Compare versions

```bash
installed=$(claude --version | awk '{print $1}')
verified=$(cat "$CLAUDE_CONFIG_DIR/.claude-code-verified-version" 2>/dev/null || echo "")
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

`WebFetch` `https://code.claude.com/docs/en/settings-reference`. Read every key
currently set in:
- this repo's `share/claude/settings.json.example` (tracked template)
- `$CLAUDE_CONFIG_DIR/settings.json` (live file)

Flag any key that's deprecated, renamed, or whose current value doesn't match
the documented type/enum for that key (this is exactly the check that would
have caught `attribution.commit: ""` — the docs say the valid values are
`"hide"` or a custom trailer string, not `""`).

## Step 4: Fix the template, ask before touching the live file

For each confirmed finding:
- **`share/claude/settings.json.example`**: edit it directly (git-tracked,
  reversible). Show the diff. Don't commit or push — ask the user first.
- **`$CLAUDE_CONFIG_DIR/settings.json`** (live): don't edit automatically.
  Report the proposed change and ask before writing it.

If nothing was found, say so plainly — don't manufacture a finding.

## Step 5: Stamp the version

Only if both WebFetch calls in steps 2–3 actually succeeded (regardless of
whether they found anything to fix), record that this version was reviewed:

```bash
echo "$installed" > "$CLAUDE_CONFIG_DIR/.claude-code-verified-version"
```

If a fetch failed, don't stamp — leave the SessionStart nudge active so the
next session retries.

## Step 6: Report

One concise summary: version jump reviewed, what (if anything) was found, what
was fixed vs. what's waiting on confirmation, and whether the stamp was
updated.
