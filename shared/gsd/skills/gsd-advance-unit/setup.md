# GSD workflow MCP — client setup

Configure at the **client repository root** (after overlay install). Paths are placeholders — substitute for your machine.

Same MCP server as [gsd-pi-cursor/setup.md](../gsd-pi-cursor/setup.md).

## Prerequisites

| Item | Value |
| --- | --- |
| **CLI** | `npm install -g gsd-pi` → `gsd` on `PATH` (bootstrap `.gsd/` only) |
| **MCP server** | `$GSD_PI_ROOT/packages/mcp-server/dist/cli.js` in `.mcp.json` |
| **`GSD_WORKFLOW_PROJECT_ROOT`** | Absolute path to **this client repo** |
| **`GSD_WORKFLOW_EXECUTORS_MODULE`** | `$GSD_AGENT_EXTENSIONS/gsd/tools/workflow-tool-executors.js` |

Enable **gsd-workflow** in Cursor → reload window.

Bootstrap GSD state once per client repo if missing:

```bash
cd /absolute/path/to/client-repo && gsd
```

Creates `.gsd/` (gsd-pi v3). Do not use legacy `.planning/`.

## Model billing

| Surface | Model |
| --- | --- |
| Cursor + `gsd-pi-cursor` skill | Cursor subscription |
| Cursor + `gsd-next-cursor` skill | Cursor subscription |
| `gsd` terminal / `/gsd next` or `/gsd auto` | gsd-pi / Copilot |

Use **`$gsd-next-cursor`** for step execution in Cursor. Terminal `/gsd next` only when the user explicitly wants gsd-pi or Copilot billing.
