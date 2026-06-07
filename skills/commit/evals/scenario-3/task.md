# Commit an API Rename Across the Codebase

## Problem/Feature Description

You are contributing to a small TypeScript HTTP client library called `fetchkit`. The library previously exposed a function called `makeRequest`, but the team has decided to rename it to `sendRequest` for consistency with the rest of the API surface. Separately, someone noticed a small unrelated typo in a comment in `src/utils.ts` and fixed it while they were in the area.

Set up the working environment first by running `inputs/setup.sh` from the repository root. This creates a git repository called `fetchkit/` with all of these edits already made as **uncommitted** changes: the renamed function definition in `src/client.ts`, the updated call sites in `src/middleware.ts`, `src/retry.ts`, and `examples/basic.ts`, the public export in `src/index.ts`, and the typo fix in `src/utils.ts`. Work inside that directory.

Your task is to record all of these changes in git following the project's conventions. After committing, write a file called `commit-summary.md` at the root of the repository (inside `fetchkit/`) that documents each commit made: the short hash, the full commit message subject, and the list of files staged in that commit.

## Output Specification

- All changes committed to git in `fetchkit/`
- `fetchkit/commit-summary.md` created with one section per commit, listing: short hash, subject line, and files included
