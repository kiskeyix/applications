---
name: review-pr
description: "Review a PR, a branch, or a diff, whether a teammate's or my own before pushing, against three questions: does it solve the ticket's problem, does it leave the codebase unsafe, does it leave it worse. Runs `/code-review high` for the bug hunt and reports only findings with a concrete failure scenario. Use when the user asks to review a PR (number or URL), a branch, work in progress, or the changes since a commit, and before every `git push` (see AGENTS.md)."
---

A review answers three questions about the change:

1. **Solves**: does it solve the problem the ticket describes?
2. **Safe**: does it leave the codebase unsafe: a correctness bug, data loss, a security hole, a production risk, a performance regression on a real path?
3. **Not worse**: is the codebase at least as good after the change as before? Complexity counts: a fix with more moving parts than its problem needs leaves the code worse even when it works.

The bar is the **boy scout rule**: a change that solves its problem and leaves the code a little better passes, however much better it could still be. PRs here carry one concern each (AGENTS.md, "The PR itself"), and the review protects that rather than widening the PR's scope.

## Process

### 1. Pin the diff

Work in a clone under `~/Projects`, cloning it there if missing. Fetch the base branch and `pull/<n>/head`, which also covers PRs from forks. Before a push, the target is the outgoing diff AGENTS.md names: the PR's diff if one exists, otherwise the commits not yet on the remote. With no base given, use `origin/main` and say so. The diff is `git diff <base>...<head>`.

Note the existing review threads so the report doesn't repeat a point already raised or resolved.

### 2. Read the problem

Understand what problem we are trying to fix.

### 3. Read the change

Read every hunk with enough surrounding code to follow its callers and callees, and follow the change into whatever it newly calls, or calls more often, far enough to know the cost. Run the repo's tests on the head commit in a `git worktree`, so the user's own checkout isn't touched. If they can't run locally, say why and fall back to the PR's automated check results from step 1.

When the diff contains executable code, run `/code-review high` on the same target. It hunts correctness bugs deeper than one read does; its findings are candidates for step 4 and go into this report, not a separate one. For docs, prose, config, and slash-command/skill definitions, your own read is the review: they have no ground truth to converge against, so adversarial review just iterates.

### 4. Judge

A finding is **significant**, and goes in the report, only when it fails one of the three questions and you can state its **failure scenario**: the concrete input or state, and the wrong outcome it produces. Weigh each candidate:

- **Caused here.** It belongs to this PR only if the diff introduced it or made it worse. A serious bug the PR didn't cause (wrong data, lost monitoring, an outage) gets one line under _Outside this PR_ as a candidate story.
- **Plausible here.** A risk whose trigger nothing in this codebase produces today is hypothetical: it is significant only when its impact is severe, and the finding names the trigger.
- **Net.** Question 3 compares against the code before the change and against the simplest change that solves the same problem. Growth the fix needs passes. Machinery beyond that fails: extra settings, guards against contradictions the design itself creates, behaviour the ticket didn't ask for. Its failure scenario is the simpler design and what it would remove.

AGENTS.md's "Pre-review self-check" lists what teammates flag in practice; use it as a lens for questions 2 and 3, under the same bar: an item with no failure scenario is not a finding.

An empty findings list is a normal outcome, and the verdict is then merge.

### 5. Report

1. **Verdict** first: _merge_, or _fix first_ naming the findings that block.
2. One short section per question, answered in a line or two even when it passes, so each reads as checked. A finding sits under its question, tagged `[blocker]` or `[please fix]`: what fails, the failure scenario, `file:line`, the smallest fix. Nothing below that bar is reported, so there are no `[nit]`s.
3. The test command and its result.
4. _Outside this PR_, only when step 4 put something there.

The report stays in the conversation. Post it to the PR only when the user asks, one inline comment per finding.
