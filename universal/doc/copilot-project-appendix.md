# Copilot project appendix (client-only)

Copy this file into your **client** repository as `doc/copilot-project-appendix.md`. It is **not** installed by the overlay script.

Use it for facts that must not live in the shared ai-playbook symlink:

- Internal API base URLs and environment names
- Codegen commands (`npm run codegen`, `protoc`, OpenAPI generate)
- Package/registry coordinates specific to this repo
- Team conventions not yet promoted to `ARCHITECTURE.md`

Copilot and other tools should read this **after** `CLAUDE.md` and `AGENTS.md` when working in this project.
