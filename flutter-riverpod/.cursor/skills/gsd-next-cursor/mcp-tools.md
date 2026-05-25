# gsd-workflow MCP — execute phase (Cursor)

**Orient (no gsd-pi LLM):** `gsd_progress`, `gsd_milestone_status`, `gsd_query`

**Plan slice (Cursor plans, MCP persists):** `gsd_plan_slice`, `gsd_plan_task` / `gsd_task_plan`

**Progress:** `gsd_task_complete`, `gsd_slice_complete`, `gsd_complete_milestone` (when appropriate)

**Optional:** `gsd_save_gate_result`, `gsd_capture_thought`

**Never for this skill:** `gsd_execute`, `gsd_status`, `gsd_result` (CLI sessions / Copilot)

Read each tool schema in Cursor before calling. Always pass `projectDir` when the server resolves home instead of the client repo.
