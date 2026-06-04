---
name: commit
description: Analyzes git diffs, stages changes, and generates descriptive commit messages following Conventional Commits format (feat, fix, chore, etc.), categorizing changes by type and scope. Use this skill whenever the user says "commit", "make a commit", "commit my changes", "commit this", "stage and commit", or anything that indicates they want to record the current state of the working tree in git.
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

### Step 2: Decide what to stage

Stage files that belong together as a logical unit. Prefer naming specific files over `git add .` to avoid accidentally including unrelated changes, secrets, or build artefacts. If the working tree contains clearly unrelated changes, stage only the relevant subset and note to the user what was left unstaged.

### Step 3: Compose the commit message

Write a message following the [Conventional Commits](https://www.conventionalcommits.org) specification:

```
<type>[(scope)][!]: <description>

[body]

[footer]
```

#### Subject line

- *type* — `feat`, `fix`, `perf`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, or `revert`.
- *scope* (optional) — the module or component affected. Omit when the change spans the whole repository.
- *!* (optional) — marks a breaking change directly before the `:`.
- *description* — short, lowercase, imperative mood (e.g., "add feature" not "added feature"), no trailing period, ≤72 characters.

### Step 4: Execute

Stage the files chosen in Step 2, then commit with the message composed in Step 3. Pass the message via a heredoc to preserve formatting.

If a pre-commit hook fails, the commit did NOT happen — fix the underlying issue, re-stage, and create a **new** commit. Never use `--amend` after a hook failure, as that would modify the previous commit rather than recording the new changes.
