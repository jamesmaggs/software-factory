# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A personal collection of skills for [Claude Code](https://claude.com/claude-code).
Each skill is authored to the portable [Agent Skills](https://agentskills.io/specification)
spec so it stays agent-agnostic. Skills live under `skills/<skill>/`:

```
skills/<skill>/
├── SKILL.md          # the skill: frontmatter (name, description) + instructions
└── evals/            # scenario evals (task.md, criteria.json, scenario.json, inputs/)
```

## Conventions

- Keep each `SKILL.md` compliant with the Agent Skills spec — skills must stay
  portable, not Claude-specific.
- When adding, renaming, or removing a skill, keep the [README](./README.md)
  Skills table in sync.
- Commit with Conventional Commits; prefer small, atomic commits.
