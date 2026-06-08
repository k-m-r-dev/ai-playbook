---
applyTo: "**"
---

# codeintel-graphify — Semantic Knowledge Graph

After `codeintel-init`, projects have an **AST-only** graph (`graphify update`).
For **semantic** INFERRED edges and richer architecture mapping, run the graphify
agent pipeline.

## When to use

- User says "graphify this project", "semantic graph", "enrich the graph"
- After init when only `graphify-out/graph.json` exists (AST baseline)
- User wants `/graphify . --mode deep`, wiki, or other graphify features

## Workflow (IDE agent — recommended)

1. Confirm baseline: `ls graphify-out/graph.json` — if missing: `graphify update .`
2. Load **`.claude/skills/graphify/SKILL.md`** (installed by `graphify install --project`)
3. Run the full pipeline equivalent to **`/graphify .`** on the project root
4. Verify: `graphify query "what are the main modules?"`

## Headless alternative (terminal + LLM key in `.env`)

```bash
codeintel-init --project . --graph-semantic
# or
graphify extract . --backend openai   # gemini, claude, deepseek, kimi
```

## Query after enrichment

- `ask "..."` — codeintel hybrid search (symbol-level)
- `graphify query "..."` — scoped graph traversal (architecture-level)

## Decision guide

| Tool | Best for |
|------|----------|
| `graphify query` | Architecture, relationships, data flow |
| `ask` | Symbol definitions, call chains, usages |
