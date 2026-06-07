# Record an API Breaking Change in the SDK

## Problem/Feature Description

Your team maintains a client SDK for an internal REST API. A major version bump is overdue: the `authenticate()` function signature has changed to require an explicit `region` parameter that did not previously exist. Any downstream callers using the old signature will break. The change is already implemented and tested — the working tree shows the modified function signature and updated tests.

Set up the working environment first by running `inputs/setup.sh` from the repository root. This creates a git repository called `sdk/` with the changes ready to commit. Work inside that directory.

Commit all the changes as a single well-described commit. The commit must clearly signal to consumers that this release is not backwards compatible.

## Output Specification

Produce a file called `commit_log.md` that records:
- The git staging command(s) you ran
- The complete commit message (including any body/footer)
