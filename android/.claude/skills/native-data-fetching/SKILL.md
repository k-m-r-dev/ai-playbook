---
name: native-data-fetching
description: >
  Generic networking and data-fetching guidance for native mobile projects. Use
  for request design, retries, caching, cancellation, mapping, and error
  handling.
---

# Native Data Fetching

## Design Rules

- Keep transport concerns separate from domain mapping and UI state
- Define timeout, retry, and cancellation behavior explicitly
- Validate and map remote payloads before they reach feature logic
- Centralize headers, auth handling, and request configuration

## Failure Handling

- Return actionable, user-safe errors
- Avoid silent fallback behavior that obscures outages or bad data
- Test success, timeout, empty, retry, and malformed-payload paths