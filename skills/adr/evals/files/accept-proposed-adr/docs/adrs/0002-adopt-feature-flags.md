# 0002. Adopt feature flags for risky releases

- Status: Proposed
- Date: 2026-03-01

## Context and drivers

Trunk-based development means unfinished or risky work can reach main before it is ready to expose to users.

## Considered options

- Feature flags gating risky changes
- Short-lived release branches

## Decision

Gate risky changes behind feature flags so they can ship dark and be enabled progressively.

## Consequences

Safer, decoupled releases; the flag lifecycle must be managed so stale flags do not accumulate.
