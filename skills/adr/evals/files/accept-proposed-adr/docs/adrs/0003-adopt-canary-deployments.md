# 0003. Adopt canary deployments

- Status: Proposed
- Date: 2026-03-10

## Context and drivers

Feature flags reduce release risk but do not catch infrastructure or performance regressions before a change reaches all users.

## Considered options

- Canary deployments routing a small traffic slice to new releases first
- Blue-green deployments with a full standby environment

## Decision

Trial canary deployments that route a small percentage of traffic to a new release before promoting it to everyone.

## Consequences

Regressions surface on a small blast radius before full rollout; requires traffic-splitting support and per-canary monitoring.
