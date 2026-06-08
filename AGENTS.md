# AGENTS.md

Operational guide for agents working in this repository.

## What this repo is

A collection of [agent skills](https://agentskills.io/specification), each
packaged as a [tessl](https://docs.tessl.io) plugin under `skills/`:

```
skills/<skill>/
├── .tessl-plugin/plugin.json   # name (engineering/<skill>), version, description
├── SKILL.md                    # the skill itself: frontmatter + instructions
└── evals/
    └── scenario-N/             # scenario evals (task.md, criteria.json, scenario.json)
```

(`scripts/` holds the quality-gate tooling; skill plugins live under `skills/`.)

`tessl.json` marks the repo as a vendored tessl project (`engineering/software-factory`);
`.mcp.json` registers the tessl MCP server.

## Skill development lifecycle

1. **Create** — `tessl skill new --workspace engineering`. Add the skill to the
   [README](./README.md) Skills table (one row, matching the existing format),
   and keep that table in sync whenever a skill is renamed or removed.
2. **Optimise** — `scripts/tessl-optimise.sh ./<skill>` runs tessl's automated
   review-and-rewrite loop until the review score reaches the threshold.
   It rewrites `SKILL.md` in place; **review the diff** before committing.
3. **Add evals** — `tessl scenario generate ./<skill> --count 5` then
   `tessl scenario download --last --output ./<skill>/evals`, or author them by hand
   (see existing `skills/commit/evals/` for the format).
4. **Iterate on evals** — `tessl eval run ./<skill>` → `tessl eval view --last`;
   read the per-criterion breakdown, tighten `SKILL.md`, re-run. Use
   `--runs 3` to gauge variance before trusting a change.
5. **Commit** — use the [commit](./skills/commit/SKILL.md) skill. Conventional Commits;
   atomic commits.
6. **Push** — versioning and publishing are automatic (see below). On push to
   `main`, once the gates pass, CI **patch-bumps** any skill whose published
   content changed and publishes it. You only touch the version yourself for a
   **minor** or **major** release — bump `plugin.json` in your commit and CI
   treats it as deliberate (no auto-bump on top). Follow semver, which maps from
   the Conventional Commit types:
   - **patch** (automatic) — `fix:` / `perf:` / `docs:` etc.; just push.
   - **minor** — any `feat:`; bump the middle version in the commit.
   - **major** — any `!` / `BREAKING CHANGE:`; bump the major version in the commit.

## Quality gates

Two tiers, configured for trunk-based development. **Before considering a skill
change done, run `scripts/tessl-review-gate.sh`** — the commit will be blocked
otherwise.

| Gate | When | Checks | Blocks on |
|------|------|--------|-----------|
| **pre-commit** (`.githooks/pre-commit`) | every `git commit` | `tessl skill lint` + `tessl skill review` on plugins with **staged** changes | review score < `TESSL_REVIEW_THRESHOLD` (default 90) |
| **CI** ([`.github/workflows/tessl-gates.yml`](./.github/workflows/tessl-gates.yml)) | every push to `main` | review gate **+** `tessl eval run` for all plugins | review < 90, or any with-skill scenario < `TESSL_EVAL_FLOOR` (default 80%) |

The eval gate runs real agents in the cloud (minutes) — that is why it lives in
CI, not in the pre-commit hook. The eval gate scores the **with-skill** variant
(`usage-spec`), i.e. the behaviour the installed skill actually produces.

Run gates manually:

```sh
scripts/tessl-review-gate.sh            # all plugins (or pass dirs: ./skills/commit)
scripts/tessl-eval-gate.sh              # all plugins with evals/ (slow)
```

Tune thresholds via env vars: `TESSL_REVIEW_THRESHOLD`, `TESSL_EVAL_FLOOR`,
`TESSL_OPTIMISE_MAX_ITERATIONS`.

## Publishing

After the gates pass, the CI `publish` job (`scripts/tessl-publish.sh`) auto-bumps
and publishes:

- A change to a skill's **published content** (anything under `skills/<skill>/`
  except `evals/`) triggers a **patch** bump, committed back as
  `chore: … [skip ci]` and pushed. Editing only `evals/` does **not** bump or
  publish.
- If the commit already changed the `version` field, that is taken as a manual
  bump (for minor/major) and left as-is.
- Each skill is then reconciled with the registry: repo version ahead →
  `tessl skill publish`; equal → nothing; **registry ahead → the job fails**
  (version drift that needs attention).

The bump commit can't loop: CI's `GITHUB_TOKEN` pushes don't trigger new runs,
and the commit carries `[skip ci]`. Do not publish manually.

## Setup

**Local (once per clone):**

```sh
git config core.hooksPath .githooks   # enable the pre-commit gate
```

Requires the `tessl` CLI (`npm install -g @tessl/cli`) and `python3`, both used
by the gate scripts.

**CI (once):** create a workspace token with `tessl api-key create` and add it as
the `TESSL_TOKEN` repository secret. The workflow reads it to authenticate.
