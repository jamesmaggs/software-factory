# Software Factory

A personal collection of harness-engineering skills for [Claude Code](https://claude.com/claude-code), authored to the portable [Agent Skills](https://agentskills.io/specification) spec.

## Skills

| Skill | Description |
|-------|-------------|
| [adr](./skills/adr/SKILL.md) | Capture architecture decisions as [MADR](https://adr.github.io/madr/) records |
| [commit](./skills/commit/SKILL.md) | Stage and commit changes using [Conventional Commits](https://www.conventionalcommits.org) |
| [skill-linter](./skills/skill-linter/SKILL.md) | Deterministically lint a SKILL.md against the [Agent Skills](https://agentskills.io/specification) spec |

## Install

This repo is a [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces).
Add it, then install the skills you want:

```sh
/plugin marketplace add jamesmaggs/software-factory
/plugin install adr@software-factory
/plugin install commit@software-factory
/plugin install skill-linter@software-factory
```

## License

MIT — see [LICENSE](./LICENSE).
