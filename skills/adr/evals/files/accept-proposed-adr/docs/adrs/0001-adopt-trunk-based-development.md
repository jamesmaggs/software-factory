# 0001. Adopt trunk-based development

- Status: Accepted
- Date: 2026-01-15

## Context and drivers

Long-lived branches caused painful, error-prone merges and slowed integration.

## Considered options

- Trunk-based development with short-lived branches
- Git Flow with release branches

## Decision

Develop on trunk with short-lived branches merged frequently.

## Consequences

Continuous integration of small changes; requires a solid CI gate to keep trunk releasable.
