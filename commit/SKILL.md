---
name: commit
description: Stage and commit the current changes using Conventional Commits. Use this skill whenever the user says "commit", "make a commit", "commit my changes", "commit this", "stage and commit", or anything that indicates they want to record the current state of the working tree in git.
license: MIT
compatability: Requires git.
allowed-tools: Bash(git status:), Bash(git diff:), Bash(git log:), Bash(git branch:), Bash(git add:), Bash(git commit:)
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

Write a message that follows the [Conventional Commits](https://www.conventionalcommits.org) specification:

```
<type>[(scope)][!]: <description>

[body]

[footer]
```

Each commit's *type* signals the corresponding [Semantic Versioning](https://semver.org) bump, so downstream tooling and humans can read the intent of a change directly from the log without diffing it.

#### Subject line

`<type>[(scope)][!]: <description>`

- *type* — pick one from the table below.
- *scope* (optional) — the module or component affected. Omit when the change spans the whole repository.
- *!* (optional) — a literal `!` directly before the `:` marks a breaking change.
- *description* — short, lowercase, imperative mood ("add x", not "added x" or "adds x"). Answer "what does this fix or enable?" rather than "what code changed?". Keep the subject under 100 characters.

#### Types and SemVer mapping

| Type       | When to use                                  | SemVer bump |
|------------|----------------------------------------------|-------------|
| `feat`     | A new user-visible capability                | MINOR       |
| `fix`      | A bug fix                                    | PATCH       |
| `perf`     | Performance improvement                      | PATCH       |
| `docs`     | Documentation-only changes                   | none        |
| `refactor` | Code change that isn't a feat or fix         | none        |
| `test`     | Adding or fixing tests                       | none        |
| `build`    | Build system or dependency changes           | none        |
| `ci`       | CI configuration                             | none        |
| `chore`    | Routine maintenance not covered above        | none        |
| `revert`   | Reverts an earlier commit                    | depends     |

Any commit can additionally be a *breaking change*, which forces a MAJOR bump regardless of type. Mark it with `!` before the `:` in the subject (e.g. `feat(checkout)!: ...`), include a `BREAKING CHANGE: <explanation>` line in the footer, or both.

#### Body (optional)

Explain the *why* of the change and any context that would help a future reader who has the diff but not the conversation. Omit entirely if the subject is self-explanatory.

#### Footer

`key: value` lines, one per line. Use `BREAKING CHANGE: <explanation>` here to describe a breaking change in detail (in addition to the `!` marker in the subject). Always include the current model as a co-author using the name from your system prompt (e.g. `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`, not just "Claude").

#### Examples

- `feat(api): send an email to the customer when a product is shipped` — minor bump
- `fix: prevent race conditions in checkout flow` — patch bump
- `feat!: drop support for Node 6` — major bump, with a `BREAKING CHANGE: use JavaScript features not available in Node 6.` line in the footer

Match the style of recent commits in this repository (capitalisation, tense, tone), but always use Conventional Commits format even if older commits do not.

### Step 4: Execute

Stage the files chosen in Step 2, then commit with the message composed in Step 3. Pass the message via a heredoc to preserve formatting.

If a pre-commit hook fails, the commit did NOT happen — fix the underlying issue, re-stage, and create a **new** commit. Never use `--amend` after a hook failure, as that would modify the previous commit rather than recording the new changes.

**Never push without explicit confirmation from the user.**
