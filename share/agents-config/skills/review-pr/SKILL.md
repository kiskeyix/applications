---
name: review-pr
description: "Review a PR, a branch, or a diff, whether a teammate's or my own before pushing, against three questions: does it solve the problem it states, does it leave the codebase unsafe, does it leave it worse. On code it runs `/code-review high` and a silent-failure pass, and it reports only findings with a concrete failure scenario. Use when the user asks to review a PR (number or URL), a branch, work in progress, or the changes since a commit, and before every `git push` (see AGENTS.md)."
---

A review answers three questions about the change:

1. **Solves**: does it solve the problem it states?
2. **Safe**: does it leave the codebase unsafe: a correctness bug, data loss, a security hole, a production risk, a performance regression on a real path?
3. **Not worse**: is the codebase at least as good after the change as before? Complexity counts: a fix with more moving parts than its problem needs leaves the code worse even when it works.

The bar is the **boy scout rule**: a change that solves its problem and leaves the code a little better passes, however much better it could still be. A change carries one concern, and the review protects that rather than widening its scope.

## Process

### 1. Pin the diff

- **Someone else's PR or branch**: work in a clone under `~/Projects`, cloning it there if missing. Fetch the base branch and `pull/<n>/head`, which also covers PRs from forks. Note the existing review threads (`gh pr view <n> --comments`) so the report doesn't repeat a point already raised or resolved.
- **Before a push**: review the checkout you are in, as it is, since unpushed commits exist nowhere else. The head is `HEAD`. The base is the branch's open PR base when it has one (`gh pr view --json baseRefName`), otherwise its upstream (`@{upstream}`).

With no base given or found, use the remote's default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`) and say so. The diff is `git diff <base>...<head>`. An empty diff has nothing to review: say so instead of giving a verdict.

### 2. Read the problem

Take the problem from the ticket the PR links, else the PR description, else the commit messages. When none of them states one, say so, and judge question 1 against what the commits say they do.

### 3. Read the change

Read every hunk with enough surrounding code to follow its callers and callees, and follow the change into whatever it newly calls, or calls more often, far enough to know the cost. Run the repo's tests on the head commit in a `git worktree`, so the user's own checkout isn't touched. Size the run to the change: a one-line change or a config change needs only the check that covers it (its test file, or a syntax or load check of the config), not the full suite; say what you ran and why it covers the change. If tests can't run locally, say why; for a PR, fall back to its check results (`gh pr checks <n>`).

When the diff contains code, start two passes on the same target at once, and wait for both before step 4:

- `/code-review high` on the PR number, or on the branch for a pre-push review.
- `pr-review-toolkit:silent-failure-hunter` in a background agent, given the diff command from step 1.

Their findings are candidates for step 4 and go into this report, not separate ones. If either isn't installed, skip it and say so. Code includes config that a program runs or enforces: CI workflows, service units, hooks, permission and settings files, and build files.

Docs, prose, and slash-command or skill definitions get your own read only. They have no ground truth to converge against, so adversarial review just iterates.

### 4. Judge

A finding is **significant**, and goes in the report, only when it fails one of the three questions and you can state its **failure scenario**: the concrete input or state, and the wrong outcome it produces. Weigh each candidate:

- **Caused here.** It belongs to this change only if the diff introduced it or made it worse. A serious bug the change didn't cause (wrong data, lost monitoring, an outage) gets one line under _Outside this change_ as a candidate follow-up.
- **Plausible here.** A risk whose trigger nothing in this codebase produces today is hypothetical: it is significant only when its impact is severe, and the finding names the trigger.
- **Net.** Question 3 compares against the code before the change and against the simplest change that solves the same problem. Growth the fix needs passes. Machinery beyond that fails: extra settings, guards against contradictions the design itself creates, behaviour nobody asked for. Its failure scenario is the simpler design and what it would remove.

When the repo's AGENTS.md has a review checklist, use it as a lens for questions 2 and 3, under the same bar: an item with no failure scenario is not a finding.

An empty findings list is a normal outcome, and the verdict is then _merge_ or _push_.

### 5. Report

1. **Verdict** first: _merge_ (a PR) or _push_ (before a push), or _fix first_ naming the findings that block.
2. One short section per question, answered in a line or two even when it passes, so each reads as checked. A finding sits under its question, tagged `[blocker]` or `[please fix]`: what fails, the failure scenario, `file:line`, the smallest fix. Nothing below that bar is reported, so there are no `[nit]`s.
3. The test command and its result.
4. _Outside this change_, only when step 4 put something there.

The report stays in the conversation. Post it to the PR only when the user asks, one inline comment per finding.

### 6. After a pre-push review

One review per push. Fix only findings from the report, in new commits, re-run the tests, and push. Don't review the fix commits again, or every fix starts another round. Tell the user which findings were left unfixed.
