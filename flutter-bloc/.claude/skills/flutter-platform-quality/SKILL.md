---
name: flutter-platform-quality
description: >
  Quality and safety guidance for Flutter development. Use for concurrency,
  performance, security, accessibility, testing, and release readiness reviews.
---

# Flutter Platform Quality

## Quality Checklist

- Main-thread work is intentional and bounded
- Async work is cancellable when lifecycle requires it
- Error states are actionable and safe for end users
- Sensitive data is protected in storage, transport, and logs
- Accessibility semantics and scalable text behavior are considered
- If a failure mode is not tested, assume it may regress
