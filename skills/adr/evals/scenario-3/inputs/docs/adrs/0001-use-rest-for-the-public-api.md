# 0001. Use REST for the public API

- Status: Accepted
- Date: 2026-01-10

## Context and drivers

External partners need a stable, well-understood HTTP interface, and the team has the most experience with REST tooling.

## Considered options

- REST over HTTP with JSON
- GraphQL
- gRPC

## Decision

Expose the public API as REST over HTTP with JSON payloads.

## Consequences

Broad client compatibility and simple debugging, at the cost of some over-fetching we accept for now.
