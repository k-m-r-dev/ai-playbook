# GitHub Copilot runtime engineering directives

## Workspace parsing strategy

- Do **not** scrape hidden or auxiliary directories (`.git`, `node_modules`, `graphify-out/cache`, `.ruflo`, vendor trees) for structural understanding.
- Use **`graphify-out/GRAPH_REPORT.md`** and **`graphify-out/graph.json`** as ground-truth structural maps when present.
- Prefer reading files listed under **Active System Topography** in **`CLAUDE.md`** over exploratory full-tree listing.

## State ingestion layer

- Always prioritize **`CLAUDE.md`** (project ledger: stack, milestone, learnings).
- Follow **`AGENTS.md`** for policy and verification commands.
- Follow **`ARCHITECTURE.md`** for module boundaries before multi-file changes.
- Follow **`SESSION_WORKFLOW.md`** for `.workflow/` session files.
- Honor constraints in **Cross-Session Learnings** inside `CLAUDE.md`.

## Token efficiency

- Avoid loading large generated artifacts into context unless the task requires them.
- For “where is X used?” questions, consult graph reports before opening dozens of files.

## Handoff

After major architectural work, suggest updating **`CLAUDE.md`** milestone and learnings sections and archiving via `.workflow/` per `SESSION_WORKFLOW.md`.
