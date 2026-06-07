# AGENTS.md

Operational guide for agents working in this repository.

## What this repo is

A collection of [agent skills](https://agentskills.io/specification), each
packaged as a [tessl](https://docs.tessl.io) plugin. Every skill lives in its
own directory:

```
<skill>/
├── .tessl-plugin/plugin.json   # name (engineering/<skill>), version, description
├── SKILL.md                    # the skill itself: frontmatter + instructions
└── evals/
    └── scenario-N/             # scenario evals (task.md, criteria.json, scenario.json)
```

`tessl.json` marks the repo as a vendored tessl project (`engineering/software-factory`);
`.mcp.json` registers the tessl MCP server.

## Skill development lifecycle

1. **Create** — `tessl skill new --workspace engineering`
2. **Optimise** — `scripts/tessl-optimise.sh ./<skill>` runs tessl's automated
   review-and-rewrite loop until the review score reaches the threshold.
   It rewrites `SKILL.md` in place; **review the diff** before committing.
3. **Add evals** — `tessl scenario generate ./<skill> --count 5` then
   `tessl scenario download --last --output ./<skill>/evals`, or author them by hand
   (see existing `commit/evals/` for the format).
4. **Iterate on evals** — `tessl eval run ./<skill>` → `tessl eval view --last`;
   read the per-criterion breakdown, tighten `SKILL.md`, re-run. Use
   `--runs 3` to gauge variance before trusting a change.
5. **Commit** — use the [commit](./commit/SKILL.md) skill. Conventional Commits;
   atomic commits; group a `SKILL.md` change with its `plugin.json` version bump.
6. **Publish** — `tessl skill publish ./<skill> --bump <patch|minor|major>`
   (auto-runs lint + review and records the score in the registry). `--dry-run`
   first. Choose the bump from the changes since the last publish, following
   semver — which maps directly from the Conventional Commit types in those
   commits:
   - **patch** — only `fix:` / `perf:` / `chore:` / `docs:` (backward-compatible fixes)
   - **minor** — any `feat:` (new backward-compatible behaviour)
   - **major** — any `!` / `BREAKING CHANGE:` (breaking change)

   When in doubt, the highest-impact change in the range wins.

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
scripts/tessl-review-gate.sh            # all plugins (or pass dirs: ./commit)
scripts/tessl-eval-gate.sh              # all plugins with evals/ (slow)
```

Tune thresholds via env vars: `TESSL_REVIEW_THRESHOLD`, `TESSL_EVAL_FLOOR`,
`TESSL_OPTIMISE_MAX_ITERATIONS`.

Bypass the hook only when genuinely necessary: `git commit --no-verify`.

## Setup

**Local (once per clone):**

```sh
git config core.hooksPath .githooks   # enable the pre-commit gate
```

Requires the `tessl` CLI (`npm install -g @tessl/cli`) and `python3`, both used
by the gate scripts.

**CI (once):** create a workspace token with `tessl api-key create` and add it as
the `TESSL_TOKEN` repository secret. The workflow reads it to authenticate.
