---
name: android-architecture
description: >
  High-level architecture guidance for native Android repositories. Use when
  planning module layout, boundaries, dependencies, migration strategy, or the
  overall shape of a feature before implementation details are chosen.
---

# Android Architecture

## Project Architecture Document

Before applying any of the guidance below, read **`ARCHITECTURE.md`** in the repository root.
That file is the project-specific source of truth for:
- App shell pattern (RootScreen, NavHost, AppSharedStateHolder, AppEventBus)
- DI ownership rules and Hilt module registration
- Data layer conventions (ApiService, DTOs, repository mapping, Room)
- Step-by-step checklist for adding a new feature

The guidance in this skill describes general patterns. `ARCHITECTURE.md` gives the concrete decisions for this project and takes precedence.

## When To Use

Use before implementing features or refactors that affect repository structure, module boundaries, dependency direction, or planning decisions.

## Focus Areas

- Keep app wiring, feature modules, core services, and design system concerns clearly separated
- Prefer stable dependency direction from app shell toward features and shared services
- Keep planning output explicit about files, risks, and migration scope
- Reuse existing module patterns before introducing new abstractions

## Planning Heuristics

- Start with the smallest change that solves the real problem
- Identify where state should live and why
- Name external boundaries clearly: networking, persistence, auth, analytics, and OS integrations
- Flag migration work instead of quietly blending incompatible patterns