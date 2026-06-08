# GSD workflow MCP — client setup

Configure at the **client repository root** (after overlay install). Paths are placeholders — substitute for your machine.

## Prerequisites

| Item | Value |
| --- | --- |
| **CLI** | `npm install -g gsd-pi` → `gsd` on `PATH` |
| **MCP server** | `$GSD_PI_ROOT/packages/mcp-server/dist/cli.js` in `.mcp.json` |
| **`GSD_WORKFLOW_PROJECT_ROOT`** | Absolute path to **this client repo** |
| **`GSD_WORKFLOW_EXECUTORS_MODULE`** | `$GSD_AGENT_EXTENSIONS/gsd/tools/workflow-tool-executors.js` |

Example `.mcp.json` fragment (adjust command/args for your Node setup):

```json
{
  "mcpServers": {
    "gsd-workflow": {
      "command": "node",
      "args": ["$GSD_PI_ROOT/packages/mcp-server/dist/cli.js"],
      "env": {
        "GSD_WORKFLOW_PROJECT_ROOT": "/absolute/path/to/client-repo",
        "GSD_WORKFLOW_EXECUTORS_MODULE": "$GSD_AGENT_EXTENSIONS/gsd/tools/workflow-tool-executors.js"
      }
    }
  }
}
```

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
| `gsd` terminal / `/gsd auto` | gsd-pi (`/login`) |

Discuss and plan in Cursor via MCP; execution handoff may use the `gsd` CLI.
