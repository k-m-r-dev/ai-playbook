#!/usr/bin/env bash
# Merge missing MCP servers from playbook config/mcp.template.json into a client .mcp.json.
# Never overwrites an existing mcpServers.<name> entry.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  merge-mcp-template.sh \
    --source-repo /path/to/ai-playbook \
    --client-repo /path/to/client \
    [--servers gsd-workflow,playbook-gsd]

Merges only missing server keys from config/mcp.template.json into client .mcp.json.
Substitutes absolute paths for client repo and playbook-gsd bin.
EOF
}

die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

SOURCE_REPO=""
CLIENT_REPO=""
SERVERS="gsd-workflow,playbook-gsd"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-repo) SOURCE_REPO="$2"; shift 2 ;;
    --client-repo) CLIENT_REPO="$2"; shift 2 ;;
    --servers) SERVERS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$SOURCE_REPO" ]] || die "--source-repo required"
[[ -n "$CLIENT_REPO" ]] || die "--client-repo required"
SOURCE_REPO="$(cd "$SOURCE_REPO" && pwd)"
CLIENT_REPO="$(cd "$CLIENT_REPO" && pwd)"

TEMPLATE="$SOURCE_REPO/config/mcp.template.json"
TARGET="$CLIENT_REPO/.mcp.json"
[[ -f "$TEMPLATE" ]] || die "missing template: $TEMPLATE"

PLAYBOOK_BIN="$SOURCE_REPO/shared/gsd/mcp/gsd-external-executor/bin/playbook-gsd-mcp.mjs"

python3 - "$TEMPLATE" "$TARGET" "$CLIENT_REPO" "$PLAYBOOK_BIN" "$SERVERS" <<'PY'
import json, sys, os
from pathlib import Path

template_path, target_path, client_repo, playbook_bin, servers_csv = sys.argv[1:]
want = [s.strip() for s in servers_csv.split(",") if s.strip()]

with open(template_path) as f:
    tmpl = json.load(f)

tmpl_servers = tmpl.get("mcpServers") or {}
if not Path(target_path).is_file():
    # Fresh file from template, with path substitution
    out = {"mcpServers": {}}
    for name in want:
        if name not in tmpl_servers:
            continue
        entry = json.loads(json.dumps(tmpl_servers[name]))
        if name == "gsd-workflow":
            entry["cwd"] = client_repo
            env = entry.setdefault("env", {})
            env["GSD_WORKFLOW_PROJECT_ROOT"] = client_repo
        if name == "playbook-gsd":
            entry["cwd"] = client_repo
            entry["args"] = [playbook_bin]
            env = entry.setdefault("env", {})
            env["GSD_WORKFLOW_PROJECT_ROOT"] = client_repo
        out["mcpServers"][name] = entry
    # Also copy other template servers if creating fresh? Keep only requested.
    Path(target_path).write_text(json.dumps(out, indent=2) + "\n")
    print(f"[COPY] {target_path} (new: {', '.join(out['mcpServers'])})")
    sys.exit(0)

with open(target_path) as f:
    client = json.load(f)

servers = client.setdefault("mcpServers", {})
added = []
skipped = []

for name in want:
    if name not in tmpl_servers:
        continue
    if name in servers:
        skipped.append(name)
        continue
    entry = json.loads(json.dumps(tmpl_servers[name]))
    if name == "gsd-workflow":
        entry["cwd"] = client_repo
        env = entry.setdefault("env", {})
        env["GSD_WORKFLOW_PROJECT_ROOT"] = client_repo
    if name == "playbook-gsd":
        entry["cwd"] = client_repo
        entry["args"] = [playbook_bin]
        env = entry.setdefault("env", {})
        env["GSD_WORKFLOW_PROJECT_ROOT"] = client_repo
    servers[name] = entry
    added.append(name)

Path(target_path).write_text(json.dumps(client, indent=2) + "\n")
if added:
    print(f"[MERGE] {target_path} added: {', '.join(added)}")
else:
    print(f"[SKIP] {target_path} already has: {', '.join(skipped) or '(none requested)'}")
if skipped:
    print(f"[KEEP] existing unchanged: {', '.join(skipped)}")
PY
