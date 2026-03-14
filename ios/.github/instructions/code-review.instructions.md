---
applyTo: "**"
excludeAgent: ["coding-agent", "Planner", "Coder", "Reviewer"]
---

# Native iOS Code Review Instructions

Review changes for correctness first, then architecture fit, security, performance, and test coverage.

## Critical Findings To Look For

- Broken data flow, race conditions, or unsafe concurrency
- Main-thread blocking or repeated expensive work in hot paths
- Secrets, tokens, or sensitive payloads in code, logs, or analytics
- Missing validation at network, storage, or user-input boundaries
- Architecture regressions that bypass established module boundaries
- Missing tests for new logic or behavior changes

## Quality Expectations

- Types should be explicit where ambiguity affects safety
- Error paths should be intentional and testable
- Public APIs should be minimal and coherent
- Copy and constants should not be scattered through implementation files
- Diffs should be easy to reason about and scoped to the requested work

## Review Style

- Be specific and actionable
- Explain why a change is risky or incorrect
- Prefer root-cause feedback over stylistic preference
- If approval is not recommended, say so directly and explain the blocking issues
