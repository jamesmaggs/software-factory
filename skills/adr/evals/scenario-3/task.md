# Supersede the Session Storage Decision

## Problem/Feature Description

The project records architecture decisions in `docs/adrs/`. ADR 0002 decided to store user sessions in memory. That decision no longer holds: the service now runs multiple replicas behind a load balancer, so in-memory sessions break horizontal scaling and drop on restart. The team has decided to move session storage to Redis. The alternatives seriously considered were sticky sessions at the load balancer and a database-backed session table; Redis won for its speed, shared access across replicas, and built-in TTLs.

Record the new decision and mark the old one as replaced, following the conventions already in `docs/adrs/`.

## Output Specification

- A new architecture decision record capturing the Redis decision (its context, the options considered, the decision, and the consequences).
- The new record should make clear which earlier decision it replaces.
- ADR 0002 marked as superseded by the new record.
- The index updated to reflect both records.
