# playbook-gsd external executor

MCP bridge so **do-next / do-next-runner** can complete gsd-pi ≥1.12 canonical tasks without unsupervised `gsd_execute`.

**Start here:** [HOW-TO.md](./HOW-TO.md) — short guide for day-to-day use.

## Tools

| Tool | When |
| --- | --- |
| `playbook_gsd_bridge_health` | Before execute (smoke / skill gate) |
| `playbook_gsd_task_begin` | Before implementing a task |
| `gsd_task_complete` | Stock gsd-workflow MCP after verify |
| `playbook_gsd_task_publish` | When complete returns `nextStage: verify` |
| `playbook_gsd_task_abort` | Cancel / stuck running Attempt |

## Configure

```json
"playbook-gsd": {
  "command": "node",
  "args": ["/absolute/path/to/ai-playbook/shared/gsd/mcp/gsd-external-executor/bin/playbook-gsd-mcp.mjs"],
  "cwd": "/absolute/path/to/client-repo",
  "env": {
    "GSD_WORKFLOW_PROJECT_ROOT": "/absolute/path/to/client-repo",
    "GSD_PI_ROOT": "/absolute/path/to/node_modules/@opengsd/gsd-pi",
    "NODE_PATH": "/absolute/path/to/node_modules/@opengsd/gsd-pi/node_modules"
  }
}
```

`bootstrap-gsd-workflow.sh --patch-mcp` merges this when the template is copied.

## Spike

See [SPIKE.md](SPIKE.md). Re-run after gsd-pi upgrades before widening the version pin in `src/resolve-gsd.mjs`.
