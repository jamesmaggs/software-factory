# AGENTS.md

Operational guide for agents working in this repository.

## What this repo is

A personal collection of [agent skills](https://agentskills.io/specification) for
harness engineering. Each skill lives under `skills/<skill>/`:

```
skills/<skill>/
├── SKILL.md          # the skill: frontmatter (name, description) + instructions
└── evals/            # scenario evals (task.md, criteria.json, scenario.json, inputs/)
```

## Conventions

- When adding, renaming, or removing a skill, keep the [README](./README.md)
  Skills table in sync.
- Commit with Conventional Commits; prefer small, atomic commits.
