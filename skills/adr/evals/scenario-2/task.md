# Record an API Versioning Strategy Decision

## Problem/Feature Description

A backend API team has been operating without a formal versioning strategy, and as the product grows, breaking changes are becoming a real problem for downstream consumers. After several team discussions, they've agreed on an approach: URL path versioning (e.g. `/v1/`, `/v2/`) will be used, with a deprecation window of at least 6 months for old versions. The alternatives that were seriously considered were header-based versioning and query parameter versioning.

The project already has some architecture decisions documented. You'll find the existing records in `docs/adr/`. The team wants the new decision added to the same documentation structure, following whatever conventions are already in place.

## Output Specification

Add the new architecture decision record to the project. The record should document the versioning strategy decision, including the context that drove it, all the options that were evaluated, the chosen approach, and its consequences. Update any existing index to include the new record.
