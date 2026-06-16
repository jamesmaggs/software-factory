# 0002. Store sessions in memory

- Status: Accepted
- Date: 2026-02-01

## Context and drivers

The first release ran as a single instance, and in-memory sessions were the quickest path to ship.

## Considered options

- In-memory session store
- Redis-backed sessions
- Database-backed sessions

## Decision

Keep session state in process memory.

## Consequences

Fast and simple, but session state is lost on restart and cannot be shared across instances.
