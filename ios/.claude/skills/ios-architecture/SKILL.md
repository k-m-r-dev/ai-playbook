---
name: ios-architecture
description: >
  High-level architecture guidance for native iOS repositories. Use when planning
  module layout, boundaries, dependencies, migration strategy, or the overall
  shape of a feature before implementation details are chosen.
---

# iOS Architecture

## Project Architecture Document

Before applying any of the guidance below, read **`ARCHITECTURE.md`** in the repository root.
That file is the project-specific source of truth for:
- App shell pattern (RootView, NavigationStack, AppSharedState, AppEventPublisher)
- DI ownership rules and singleton registration
- Data layer conventions (APIClient, DTOs, repository mapping)
- Step-by-step checklist for adding a new feature

The guidance in this skill describes general patterns. `ARCHITECTURE.md` gives the concrete decisions for this project and takes precedence.

## When To Use

Use before implementing features or refactors that affect repository structure, module boundaries, dependency direction, or planning decisions.

## Focus Areas

- Keep app composition, feature modules, core services, and design system concerns clearly separated
- Prefer stable dependency direction from app shell toward features and shared services
- Keep planning output explicit about files, risks, and migration scope
- Reuse existing module patterns before introducing new abstractions

## Planning Heuristics

- Start with the smallest change that solves the real problem
- Identify where state should live and why
- Name external boundaries clearly: networking, persistence, auth, analytics, and OS integrations
- Flag migration work instead of quietly blending incompatible patterns