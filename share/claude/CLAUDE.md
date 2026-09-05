# Global principles

Personal defaults for how I want to work with Claude Code, across every
repo. Project-level `CLAUDE.md` files take precedence for project-specific
facts; this file is for standing preferences that don't belong in any one
repo. Several sections below draw on Andrej Karpathy's public notes on
where LLM coding tends to go wrong: quietly running with a wrong
assumption, bloating simple problems into big abstractions, and touching
code beyond what the task asked for.

**Tradeoff:** this biases toward caution over speed. For a trivial task
(a typo, an obvious one-liner) use judgment — it doesn't need the full
ceremony below.

## Think before coding

- Don't silently pick an interpretation when the request is ambiguous —
  say what the readings are and which one you're going with, or ask.
- State assumptions out loud instead of quietly building on them.
- If a simpler approach exists than the one implied by the request, say
  so — push back rather than build the more complicated thing to avoid
  friction.
- If something is genuinely unclear, stop and name what's confusing
  instead of guessing and hoping it was right.

## Simplicity first

- Minimum code that solves the problem — nothing speculative.
- No features, flexibility, or configurability beyond what was asked for.
- No error handling for states that can't happen given the code's actual
  guarantees.
- Simple and boring beats clever. Clever code is exactly the code an LLM
  (or a human skimming a diff) is most likely to misread.
- Three similar lines beats the wrong shared abstraction.
- Gut check: if this is 200 lines and could be 50, or a senior engineer
  would call it overcomplicated, rewrite it.

## Surgical changes

- Touch only what the task requires. Don't "improve" adjacent code,
  comments, or formatting while you're in there, and don't refactor
  something that isn't broken.
- Match the surrounding style even if you'd have written it differently.
- Only remove code your own change made unreachable (now-unused imports,
  variables, functions). Leave pre-existing dead code alone — mention it,
  don't delete it, unless asked to clean it up.
- Every changed line should trace back to the actual request.

## Goal-driven execution

- Turn vague asks into a verifiable goal before starting: "fix the bug"
  becomes "write a test that reproduces it, then make it pass"; "add
  validation" becomes "write tests for the invalid inputs, then make them
  pass."
- For multi-step work, state a short plan with a verification for each
  step, not just a list of actions.
- Loop change → run → observe until the verification actually passes.
  Don't stack further changes on top of a step you haven't checked.
- Commit often enough that any step can be reverted on its own — cheap
  rollback is what makes looping like this safe.

## Working with AI-generated code

- Read every diff before it lands, line by line. Understanding the change
  is the job now that writing it is cheap — don't rubber-stamp output you
  haven't actually read.
- "Vibe coding" — accepting output on faith because it runs — is fine for
  a disposable prototype or a spike I'll throw away. It is never fine for
  anything that gets committed, deployed, or handed to someone else.
- Treat confident-sounding output as unverified until it's actually been
  run, tested, or read against the source it claims to reflect. Fluency is
  not correctness.
- If I can't explain why generated code works, that's a signal to slow
  down and read it, not a reason to move on. Building (or re-deriving)
  something from scratch is still the fastest way to actually understand
  it — don't let generation substitute for that when the goal is learning.

## Git

- New commits, not amends, unless explicitly asked to amend.
- Never force-push, reset --hard, or otherwise rewrite history that's
  already shared, without asking first.
- Check `git status`/`git diff` before staging broadly (`git add -A` /
  `.`) — it's easy to sweep in a stray file that shouldn't be committed.

## Docs

- A `CLAUDE.md` (this one included) should read like a map, not a diary:
  architecture and how-to-run, not a change log. If it's derivable from
  `git log` or the code itself, it doesn't belong here.
- Keep it short enough that adding one more fact should mean cutting one
  that's stopped earning its place.
