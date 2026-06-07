---
name: commit
description: Analyzes git diffs, stages changes, and generates descriptive commit messages following Conventional Commits format (feat, fix, chore, etc.), categorizing changes by type and scope. Splits unrelated changes into small atomic commits and groups semantically-coupled changes (e.g. code with its tests). Use this skill whenever the user says "commit", "make a commit", "commit my changes", "commit this", "stage and commit", or anything that indicates they want to record the current state of the working tree in git.
allowed-tools: Bash
license: MIT
compatibility: Requires git.
---

# Commit

## Instructions

Follow these steps in order.

### Step 1: Understand the current state

Run these in parallel:
- `git status` — see what's modified, staged, and untracked
- `git diff HEAD` — read the full diff of all changes
- `git log --oneline -10` — pick up the repo's commit style (capitalisation, scope conventions, tone)

If `git status` shows nothing to commit, tell the user and stop — don't create an empty commit.

### Step 2: Plan atomic commits

Default to **small, atomic commits**: each commit captures exactly **one semantic change** — a single fix, feature, refactor or decision.

When the working tree mixes several unrelated changes, **split them into separate commits** rather than bundling them. Conversely, **group changes that are only meaningful together** into one commit:

- code and the tests that exercise it,
- an API change and the call sites updated in lockstep,
- a change and the lockfile or generated output it produces,
- a renamed or moved file and the references updated to point at it.

Decide with this test: *would splitting these leave a commit that can't build or pass on its own, or that is meaningless without the other?* If yes, keep them together; otherwise prefer the smaller commit.

Produce an ordered plan — for each commit, the specific files it includes and a one-line message. When there is more than one commit, order them so any prerequisite lands first (the referenced thing before the referencer), and briefly tell the user the plan.

### Step 3: Compose each commit message

For every planned commit, write a [Conventional Commits](https://www.conventionalcommits.org) message:

```
<type>[(scope)][!]: <description>

[body]

[footer]
```

- *type*: `feat`, `fix`, `perf`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, `revert`.
- *scope* (optional): module affected; omit for repo-wide changes.
- *!* before the `:` marks a breaking change.
- *description*: lowercase, imperative, no trailing period, ≤72 characters.

### Step 4: Execute

Work through the planned commits in order. For each: stage **only that commit's specific files** (prefer naming files over `git add .`, to avoid sweeping in unrelated changes, secrets or build artefacts), then commit with its message via a heredoc to preserve formatting.

If a pre-commit hook fails, the commit did NOT happen — fix the underlying issue, re-stage, and create a **new** commit. Never use `--amend` after a hook failure, as that would modify the previous commit rather than recording the new changes.
