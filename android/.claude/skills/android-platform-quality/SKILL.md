---
name: android-platform-quality
description: >
  Quality and safety guidance for native Android development. Use for
  concurrency, performance, security, accessibility, testing, and release
  readiness reviews.
---

# Android Platform Quality

## Quality Checklist

- Main-thread usage is intentional and limited
- Async work is cancellable where lifecycle or user intent requires it
- Error states are actionable and safe for end users
- Sensitive data is protected in storage, transport, and logs
- Accessibility labels, semantics, and scalable text behavior are considered
- Observability covers failure cases without leaking private data

## Performance Focus

- Avoid repeated parsing, formatting, or recomposition-heavy work in hot paths
- Prefer incremental UI updates over full refreshes where possible
- Measure before introducing complexity for optimization

## Security Focus

- Validate server and local input boundaries
- Protect secrets and session material
- Keep permission scopes narrow and justified

## Review Heuristics

- If a change is hard to explain, it is hard to trust
- If a diff widens scope unnecessarily, reduce it
- If a failure mode is not tested, assume it may regress
