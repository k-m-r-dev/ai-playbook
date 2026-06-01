---
name: codeintel-graphify
description: >
  Semantic knowledge-graph enrichment after codeintel-init. Wraps the graphify
  skill (/graphify). Use when the user says "/codeintel-graphify", "graphify this
  project", "semantic graph", "enrich the graph", "run graphify mapping", or after
  init when only an AST graph exists and they want LLM-backed INFERRED edges.
trigger: /codeintel-graphify
---

# codeintel-graphify

Post-init wrapper for **`/graphify .`** — runs the full graphify agent pipeline
(semantic extraction via the IDE's native AI) on a project that already has
codeintel-ask set up.

## When to use

- After `codeintel-init` (AST graph exists in `graphify-out/graph.json` but no semantic pass)
- User skipped `--graph-semantic` or has no API keys in `.env`
- User wants richer INFERRED edges, `--mode deep`, wiki, or other graphify features
- Prefer agent-driven mapping over headless `graphify extract` in the terminal

## Prerequisites

1. `codeintel-init` has been run in the project (or at minimum `graphify update .`)
2. `graphify` CLI on PATH (`uv tool install graphifyy`)
3. graphify skill deployed (`graphify install --project` — done by init)

## Workflow

### Step 1 — Check baseline graph

```bash
codeintel-status
ls graphify-out/graph.json 2>/dev/null || echo "no graph yet"
```

If **no** `graphify-out/graph.json`:

```bash
graphify update .
```

### Step 2 — Invoke the graphify skill (required)

Load and follow **`.claude/skills/graphify/SKILL.md`** (installed by graphify / init).
Do **not** improvise graphify steps — the graphify skill owns the full pipeline.

Run the equivalent of:

```
/graphify .
```

Use the **project root** as the path (where `graphify-out/` lives).

Optional flags (pass through to graphify skill):

- `/graphify . --update` — incremental refresh after code changes
- `/graphify . --mode deep` — aggressive semantic extraction
- `/graphify . --wiki` — build agent-crawlable wiki under `graphify-out/wiki/`

### Step 3 — Verify

```bash
ls -la graphify-out/graph.json graphify-out/GRAPH_REPORT.md
graphify query "what are the main modules?"
```

### Step 4 — Remind user how to query

- **Terminal:** `ask "where is X?"` (codeintel-ask hybrid search)
- **Graph:** `graphify query "how does Y work?"` (scoped subgraph)
- **Chat:** MCP `ask_codebase` or continue using `/graphify query` patterns

## Headless alternative (no IDE agent)

If the user has LLM keys in `.env` and prefers the terminal:

```bash
codeintel-init --project . --graph-semantic
# or
graphify extract . --backend openai   # gemini, claude, deepseek, kimi
```

Or invoke **`@Graphify`** agent — it supports both native chat (`/graphify .`) and
terminal CLI in one workflow.

## Do not

- Re-run full `codeintel-init` unless index/MCP also need refresh
- Commit API keys — keep them in gitignored `.env`
- Skip the graphify skill and call random extract flags without reading graphify docs
