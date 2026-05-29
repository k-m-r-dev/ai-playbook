# [Project Name] — Architecture

> **Template:** Replace title, diagrams, and paths before use. This file is the **canonical structure** document; `CLAUDE.md` holds session/milestone state; `AGENTS.md` holds cross-cutting policy.

## Purpose

Describe what this system does, who consumes it, and the primary runtime boundaries (single service, monorepo, client+API, etc.).

## System context

```text
[External actors] → [This system] → [Dependencies: DB, queue, third-party APIs]
```

## Layering & dependency rule

Inner layers do not depend on outer layers. Example (adapt names):

| Layer | Responsibility | Depends on |
|-------|----------------|------------|
| Domain | entities, invariants, ports | nothing outward |
| Application | use cases, orchestration | domain |
| Infrastructure | DB, HTTP clients, FS | domain ports |
| Delivery | HTTP handlers, CLI, UI | application |

**Rule:** New code must respect existing dependency direction documented here.

## Module map

| Path | Role |
|------|------|
| `[e.g. src/domain/]` | Core models and ports |
| `[e.g. src/app/]` | Use cases / services |
| `[e.g. src/adapters/]` | Implementations |
| `[e.g. src/api/]` | HTTP/GraphQL/gRPC surface |

Link graphify hubs from `CLAUDE.md` when `graphify build` has been run.

## Cross-cutting concerns

- **Configuration:** [env files, feature flags]
- **Auth:** [mechanism, token storage, failure mode]
- **Errors:** [shape, logging, user-visible messages]
- **Observability:** [metrics, tracing, log fields]
- **Data:** [migrations, retention, PII handling]

## Verification

Commands that must pass before merge (project-specific):

```bash
[e.g. npm run build && npm test]
```

## Adding a feature (checklist)

1. Confirm fit with layer boundaries above.
2. Add or extend tests at the appropriate layer.
3. Update `ARCHITECTURE.md` if module map or dependencies change.
4. Run verification commands; update `.workflow/progress_tracker.md` if shipped.
5. Append durable decisions to `CLAUDE.md` **Cross-Session Learnings** after ruflo consolidate.

## Related playbooks

- Mobile-native depth: install `ios` / `android` / `flutter-*` overlay instead of or atop `universal`.
- Framework setup: `FRAMEWORK.md` in ai-playbook repository.
