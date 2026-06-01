---
applyTo: "**"
---

# codeintel-ask — Codebase Intelligence

This project has a pre-built semantic index and knowledge graph. Use `ask` before
reaching for file reads or grep when the question is about how code is organised,
where something is defined, or what calls what.

## When to use it

- "Where is X implemented / defined?"
- "What calls / imports Y?"
- "How does feature Z work end-to-end?"
- "What would break if I change this type / interface?"

## How to use it

```bash
# Natural-language question
ask "where is the authentication logic?"

# Symbol lookup
ask "WorkOrderCard definition"
ask "what imports createAxiosInstance"

# Impact analysis
ask "what imports or extends BasePaymentService"

# Check freshness before relying on results
codeintel-status
```

Results include `file`, `line`, and a code snippet — open the file at that line for full context.

## Monorepo scope

In this repo there are two apps. To scope a query to one workspace:
```bash
ask "question" --workspace mobile-app
ask "question" --workspace app-v2
```

## After a merge or branch switch

If `codeintel-status` reports the index is stale, rebuild before querying:
```bash
ask-index                        # rebuild vector index only (fast)
codeintel-init --update-graph    # rebuild graph + index
```

## When `ask` is unavailable

Fall back to `#codebase` (workspace search) for broad questions, or exact
`grep_search` for known strings. Run `codeintel-init` to set the tool up.

## Semantic graph enrichment

See `.github/instructions/codeintel-graphify.instructions.md` — run **`/graphify .`**
(via graphify skill) or `codeintel-init --graph-semantic` for headless LLM extract.
