---
name: codeintel-ask
description: >
  Use codeintel-ask to query a project's codebase intelligence layer — hybrid
  vector search + graph traversal + LSP. Use when answering questions about where
  code lives, what imports what, how a feature is wired, impact of a change, or
  when asked to "ask the codebase", "find where X is implemented", "what calls Y",
  "is the index stale", or "show me the graph for Z".
---

# codeintel-ask

## What it provides

Core CLI commands installed into the project's virtualenv (or system):

| Command | Purpose |
|---|---|
| `ask "<question>"` | Hybrid search: vector similarity + grep + graph + LSP |
| `ask-index` | Build / rebuild the LanceDB vector index |
| `codeintel-init` | One-command setup (graphify, index, hooks, agent configs) |
| `codeintel-status` | Check whether the index is stale vs HEAD |
| `codeintel-uninstall` | Remove from project and/or system |

## When to use this skill

- "Where is X implemented?"
- "What calls / imports Y?"
- "How does feature Z work end-to-end?", "Breakdown the feature X"
- "Provide a spec for", "Reverse engineer the legacy code"
- "Is the index up to date?"
- "Show me all usages of this hook / component / function"
- "What changed since the index was built?"
- Any question that benefits from codebase-wide search rather than reading one file at a time

## Workflow

### Step 1 — Check if the tool is available

```bash
which ask || echo "not on PATH"
codeintel-status   # shows index SHA vs HEAD SHA
```

If not on PATH:
```bash
uv tool install codeintel-ask   # or: pipx install codeintel-ask
```

If the index doesn't exist yet:
```bash
codeintel-init   # full setup wizard
```

### Step 2 — Query the codebase

```bash
# Natural language — best starting point
ask "where is the authentication logic?"
ask "what calls useWorkOrders?"
ask "how is the token refresh flow implemented?"
ask "breakdown the WorkOrderDetails UI in mobile-app"
ask "provide a spec for the payment flow"

# Precise symbol lookup
ask "UserProfileController definition"
ask "what imports createAxiosInstance"

# Impact analysis
ask "what would break if I change the WorkOrder type?"
```

### Step 3 — Interpret results

Results arrive as ranked snippets with file paths, line numbers, and a score. Each result has:
- `file` — workspace-relative path
- `line` — starting line number
- `snippet` — the matching code
- `score` — relevance (higher = more relevant)
- `source` — which retriever matched (`vector`, `grep`, `graph`, `lsp`)

Use the file + line to read the exact context with `read_file` before drawing conclusions.

### Step 4 — Check staleness when it matters

```bash
codeintel-status
```

Output tells you:
- **Fresh** — index SHA matches HEAD, results are reliable
- **Stale** — files changed since the index was built; run `ask-index` to rebuild

## Monorepo behaviour

In a monorepo (e.g. `apps/mobile-app` + `apps/app-v2`):
- `graphify-out/` lives at the **repo root** (maps the entire monorepo)
- `.codeintel/` lives per **workspace** (separate index per app)
- Pass `--workspace <name>` to scope queries: `ask "where is X" --workspace mobile-app`

## Language onboarding model

Language support is **fully YAML-driven** — no existing Python files need editing:

```
codeintel_ask/languages/<lang>/
  config.yaml     ← all stack metadata (required)
  __init__.py     ← empty package marker (required)
  imports.py      ← import-chain expansion plugin (optional)
  trace.py        ← trace pattern plugin (optional)
  tests/
    test_language.py  ← language-specific tests (recommended)
```

To add a new language: create the directory + `config.yaml`. See `docs/adding-language-platform-support.md` for the full `config.yaml` field reference.

Test your addition:
```bash
python codeintel_ask/languages/test_all_languages.py --lang <lang>
python -m pytest codeintel_ask/languages/<lang>/tests/ -v
```

## Key flags

```bash
# Init flags
codeintel-init --update-graph          # re-extract only changed files (fast)
codeintel-init --graph-semantic        # AST graph + headless LLM extract (key in .env)
codeintel-init --graph-backend openai  # force extract backend
codeintel-init --no-graph-dedup        # fix false-merge in monorepos with similarly-named nodes
codeintel-init --no-index              # skip vector index (graph only)
codeintel-init --force                 # re-run all steps even if already done

# Query flags
ask "question" --explain               # show reasoning behind results
ask "question" --top 10                # return more results (default: 5)
ask "question" --stack react_native    # force stack (skip auto-detect)
ask "question" --stack php             # force PHP stack preset
ask "question" --stack rust            # force Rust stack preset

# Status flags
codeintel-status --all-workspaces      # check every registered workspace
```

## Common patterns

### Finding where a feature lives
```bash
ask "payment processing flow"
# → reads top results → read_file on the most relevant ones
```

### Tracing a call chain
```bash
ask "what calls submitWorkOrder"
ask "what does submitWorkOrder call"
# Build the chain from the two result sets
```

### Pre-PR impact check
```bash
ask "what imports or extends BasePaymentService"
# → identifies all callers before you change the interface
```

### After a merge / branch switch
```bash
codeintel-status
# If stale:
ask-index    # rebuild index
# Or for graph too:
codeintel-init --update-graph --no-index --no-lsp --no-agents --no-gitignore --no-hooks
```

## After init — semantic knowledge graph

`codeintel-init` builds an **AST-only** graph (`graphify update`). For **semantic** INFERRED edges:

| Method | When |
|--------|------|
| **`/codeintel-graphify`** in chat | Wraps `/graphify .` — uses IDE agent (recommended) |
| **`/graphify .`** | Full graphify skill pipeline |
| **`codeintel-init --graph-semantic`** | Headless `graphify extract` (needs LLM key in `.env`) |

Load `.claude/skills/codeintel-graphify/SKILL.md` when the user asks to enrich the graph after init.

## What NOT to use it for

- Reading a single file you already know the path of → use `read_file` directly
- Grep for an exact string → `grep_search` is faster
- Listing directory contents → `list_dir`
- Questions about running code (tests, build output) → use the terminal

## Error signals

| Message | Meaning | Fix |
|---|---|---|
| `index not found` | `ask-index` was never run | `codeintel-init` or `ask-index` |
| `graphify not found` | graphify not installed | `uv tool install graphifyy` |
| `stale (N files changed)` | Code changed since last index | `ask-index` |
| `graph.json missing` | graphify was never run | `codeintel-init` |
