---
name: CodeIntelGraphify
description: >
  Post-init semantic graph enrichment for codeintel-ask projects. Prefer @Graphify
  for general /graphify . runs. Use @CodeIntelGraphify when codeintel-init already
  ran and user wants codeintel-aware pre-checks before graphify. Wraps /graphify .
argumentHint: "Enrich graph after codeintel-init (or use @Graphify for general runs)"
tools:
  - run_in_terminal
  - read_file
  - grep_search
readonly: false
---

# CodeIntelGraphify Agent

## Purpose

**Codeintel-aware** wrapper for graph enrichment after `codeintel-init`.
For general `/graphify .` runs (chat or terminal), use **`@Graphify`** instead.

## On every invocation

1. Run `codeintel-status` — confirm project is initialized
2. Check `graphify-out/graph.json`; if missing: `graphify update .`
3. Delegate to **`@Graphify`** (load `.claude/agents/Graphify.md`) OR load
   `.claude/skills/codeintel-graphify/SKILL.md` → `.claude/skills/graphify/SKILL.md`
4. Run **`/graphify .`** (chat) or terminal commands per Graphify agent Step B
5. Verify: `graphify query "<smoke-test question>"`

## Headless (terminal)

```bash
codeintel-init --project . --graph-semantic
graphify extract . --backend openai
```

See `@Graphify` agent for full terminal command reference.
