---
applyTo: "**"
excludeAgent: ["coding-agent", "Planner", "Coder", "Reviewer"]
---

# Flutter Riverpod Code Review Instructions

Review changes for correctness first, then architecture fit, security, performance, and test coverage.

## Critical Findings To Look For

- Broken state flow or provider ownership issues
- Missing validation at network, storage, or user-input boundaries
- Sensitive data in code or logs
- Missing tests for new logic or behavior changes
