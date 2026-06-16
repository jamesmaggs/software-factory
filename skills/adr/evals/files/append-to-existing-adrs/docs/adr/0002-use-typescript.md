# 0002. Use TypeScript

- Status: Accepted
- Date: 2025-02-03

## Context and drivers

JavaScript's dynamic typing has led to several runtime bugs in production. The team wants better IDE support and earlier error detection.

## Considered options

- TypeScript - static typing, compiles to JS, wide adoption
- Plain JavaScript with JSDoc - no compilation step, type hints via comments
- Flow - Facebook's type checker, less widely adopted

## Decision

We will adopt TypeScript across the entire codebase. The benefits of static analysis outweigh the cost of a compilation step.

## Consequences

- Positive: Catch type errors at compile time.
- Positive: Better IDE autocompletion and refactoring support.
- Negative: All developers must learn TypeScript specifics.
- Negative: Build pipeline becomes slightly more complex.
