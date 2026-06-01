---
applyTo: "**"
---

# @Graphify — Knowledge Graph Agent

Run the **graphify** pipeline on this project — in **native AI chat** or **terminal**.

## Invoke when

- User says `/graphify .`, `@Graphify`, "build the knowledge graph", "run graphify"
- Architecture / relationship questions when `graphify-out/graph.json` exists
- User wants semantic graph mapping (chat or headless CLI)

## Mode A — Native AI chat (default in Copilot Chat)

1. Ensure `.claude/skills/graphify/SKILL.md` exists (`graphify install --project`)
2. Load the graphify skill and run **`/graphify .`** on the project root
3. Pass flags: `--update`, `--mode deep`, `--wiki` as requested

**Fast path:** If `graphify-out/graph.json` exists and user asks a question →
`graphify query "<question>"` (no full rebuild).

## Mode B — Terminal (headless / automation)

```bash
graphify update .                        # AST baseline (no API key)
graphify extract . --backend openai    # semantic (LLM key in .env)
graphify query "how does auth work?"     # query existing graph
codeintel-init --project . --graph-semantic   # codeintel-ask integrated path
```

## Verify

```bash
ls graphify-out/graph.json
graphify query "main entry points?"
```

## With codeintel-ask

- AST graph may already exist after `codeintel-init`
- Symbol search: `ask "..."` · Architecture: `graphify query "..."`
- See also: `.github/instructions/codeintel-graphify.instructions.md`
