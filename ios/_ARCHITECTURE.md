# [App Name] – Clean Architecture + MVVM

This document describes how **Clean Architecture** and **MVVM** work together in the app, and how **Factory** (or your chosen DI framework) is used for dependency injection.

> **Template note:** Replace `[App Name]`, all placeholder paths, and all `[...]` tokens with project-specific values before committing this file to the client repository.

---

## Flow of control

```
View (SwiftUI) → ViewModel (MVVM) → Use Case (Clean) → Repository (Clean)
```

- **View**: Dumb. Displays state and forwards user actions to the ViewModel.
- **ViewModel**: Interface adapter. `ObservableObject` holding UI state; calls Use Cases; depends on protocols, not concrete types.
- **Use Case**: Application business logic. Depends only on repository (and other domain) abstractions.
- **Repository**: Abstraction (protocol) for data. Implementations live in `Core/Data` (API, SwiftData, local storage, etc.).

## Dependency rule

Inner layers do not know about outer layers:

- **Domain**: Entities, Repository protocols, Use Cases. No SwiftUI, no UIKit, no concrete data sources.
- **Data**: Concrete implementations of repository protocols (network, persistence, cache).
- **Presentation**: ViewModels and Views. ViewModels depend on Use Cases (via protocols or concrete types resolved by DI).

Dependency injection (Factory) is what allows the app to satisfy the dependency rule: the composition root wires concrete implementations to protocols.

---

## Layout

| Folder | Purpose |
|--------|---------|
| `App/` | App entry point and shared app-level UI/utilities. |
| `Core/` | Domain (Entities, Repository protocols, Use Cases), Data (repository implementations, network, DTOs), DI (Factory registrations). |
| `DesignSystem/` | Colors, typography, spacing from the design source (e.g. Figma). |
| `Features/` | Feature modules: Views, ViewModels, and per-feature `dictionary.swift` / `constants.swift`. |

Current app entry file:
- `App/[AppName]App.swift`

---

## App shell architecture (mandatory)

The app shell must follow a single, consistent pattern for post-login layout, navigation, and app-wide communication.

### 1) Root hierarchy and background

- `RootView` is the composition root for high-level app state.
- Authenticated flow is rendered in a root `ZStack` with `AppCommonBackground` at the base.
- After login, all authenticated root layers use `.ignoresSafeArea()` to prevent status bar / safe-area clipping regressions.
- Do not use ad hoc per-screen top-area background hacks for authenticated screens; rely on `AppCommonBackground`.

Current root files:
- `Features/RootView/Views/RootView.swift`
- `Features/RootView/ViewModels/RootViewModel.swift`

### 2) Navigation model

- Navigation is based on SwiftUI `NavigationStack`.
- Each tab has its own independent `NavigationPath`.
- All tab paths are owned by `AppNavigationCoordinator` (not local per-view state).
- Back navigation from shared navigation UI (for example `appNavigationBar`) must route through `AppNavigationCoordinator`.
- Navigation bar back button policy:
  - `appNavigationBar` defaults to `showsBackButton: false`.
  - Parent tab/root views keep back button hidden by default.
  - Child/pushed screens must opt in with `showsBackButton: true` when needed.
  - When back button is hidden, title remains left-aligned (no leading placeholder gap).

Current coordinator files:
- `Features/Navigation/AppNavigationCoordinator.swift`
- `Features/MainTabView/Views/TabItem.swift`

### 3) Shared cross-tab state

- Shared UI/app state is centralized in `AppSharedState`.
- Tab selection is owned by `AppSharedState.selectedTab`.
- Cross-tab features must read/write shared state through `AppSharedState`, not by reaching into sibling views/view models.
- On logout, shared app state must be reset (`AppSharedState.clear()`).

Current shared-state file:
- `Features/Navigation/AppSharedState.swift`

### 4) App-wide events

- App-wide events are published via `AppEventPublisher` (Combine subjects).
- Do not introduce new app-wide `NotificationCenter` events for internal feature coordination.
- Event producers publish through typed methods on `AppEventPublisher` (for example auth-state and preferences changes).
- Event consumers subscribe via injected `AppEventPublisher` dependency.

Current event file:
- `Features/Navigation/AppEventPublisher.swift`

### 5) DI and ownership rules for shell types

- `AppEventPublisher`, `AppSharedState`, and `AppNavigationCoordinator` are app-wide singletons registered in `Core/DI/Container+Registration.swift`.
- ViewModels that need app-wide coordination must receive these dependencies via constructor injection.
- Avoid direct cross-feature calls such as manually refreshing unrelated view models from views; prefer event publication + subscriber reaction.
- Logout/login transitions should be driven by auth events and `RootViewModel` state refresh.

---

## Navigation migration plan (feature-owned stack)

Goal: move from tab-shell-managed navigation containers + title preference plumbing to **feature-owned** `NavigationStack` + reusable navigation bar modifiers.

Migration steps (repeat per tab in order):
1. Create `<TabName>TabRootView` inside `Features/<TabName>/Views/`.
2. Move `NavigationStack(path: $appNavigationCoordinator.<tabPath>)` into that root view.
3. Attach the shared header via `.appNavigationBar(title:onBack:isInteractionEnabled:trailingButton:)` inside the root view.
4. Wire back button actions to `AppNavigationCoordinator.navigateBack(in:)`.
5. Keep using a consistent trailing button pattern (e.g. a language toggle or settings icon) until a more generic trailing header pattern is introduced.
6. Remove the tab's usage of any legacy navigation container and stop using preference-based nav title plumbing for that tab.

Final cleanup after all tabs are migrated:
- Remove legacy `AppNavigationContainer` and preference plumbing if no longer used.
- Keep `AppNavigationCoordinator` and `AppSharedState` as the single sources of truth for cross-tab navigation state.

---

## API and environment configuration

- **Base URL**: Centralised in `Core/Data/Network/APIConfiguration.swift`. Use an `Environment` enum (`.dev` / `.staging` / `.prod`) to switch:
  - **Dev**: `http://localhost:[port]`
  - **Staging**: `https://staging-api.[domain]`
  - **Prod**: `https://api.[domain]`
- **Current environment**: `APIConfiguration.current` is `.dev` in DEBUG builds and `.prod` in release. All network code uses `APIConfiguration.baseURL` so a single place controls the backend.
- **Adding a new environment**: Add a case to `Environment` and its `baseURL`; optionally switch at runtime (e.g. via a launch argument or build configuration) instead of `#if DEBUG`.

---

## Data layer (network, DTOs, repositories)

- **Network**: `APIClient` (protocol `APIClientProtocol`) performs HTTP requests with base URL and default headers. Repositories depend on `APIClientProtocol`, not `URLSession` directly.
- **Endpoints**: Paths live in `Core/Data/Network/APIEndpoints.swift`. No base URL here; the client appends them to `APIConfiguration.baseURL`.
- **DTOs**: Request/response shapes for the API live in `Core/Data/DTOs/`. Use `Encodable` for request bodies and `Decodable` for responses. Domain stays free of API details; repositories map between domain types and DTOs.
- **Repositories**: Implement domain repository protocols in `Core/Data/Repositories/`. They take an `APIClientProtocol` (injected via DI), call endpoints, decode DTOs, and either return domain types or persist as needed. Throw `APIError` or domain errors; do not expose DTOs to Use Cases or ViewModels.

---

## Adding a new feature

1. **Entity** (if needed): `Core/Domain/Entities/`.
2. **Repository protocol**: `Core/Domain/Repositories/`.
3. **Use Case**: `Core/Domain/UseCases/` – depends on repository protocol only.
4. **DTOs** (if API): `Core/Data/DTOs/` – request/response types; keep API shape in Data layer.
5. **Endpoint** (if API): Add path in `Core/Data/Network/APIEndpoints.swift`.
6. **Repository implementation**: `Core/Data/Repositories/` – inject `APIClientProtocol`, call endpoint, map DTOs to domain or persist.
7. **Register in DI**: `Core/DI/Container+Registration.swift` – register `apiClient` if new, then repository and use case.
8. **ViewModel**: `Features/<Feature>/ViewModels/` – init takes use case (or resolve from Container).
9. **View**: `Features/<Feature>/Views/` – init takes ViewModel; bindings and actions only.
10. **Copy / constants**: `Features/<Feature>/dictionary.swift` and `constants.swift`.

---

## Design system

- **Colors**: `DesignSystem/Colors.swift` – design token variables (Default & Accessible, Light & Dark). Use adaptive color accessors for automatic light/dark mode support.
- **Brand colours**: `AppColors.Brand` – define brand palette here and keep raw values out of feature code.
- **Gradients**: Define named gradient presets (e.g. `LinearGradient.appBackgroundGradient`) used consistently across the app.
- **Typography**: `DesignSystem/Typography.swift` – text styles sourced from the design file (e.g. SF Pro Text, SF Pro Display).
- **Constants**: `DesignSystem/constants.swift` – spacing, radii, and non-user-facing design tokens.

Source: [Link to Figma or design file]

---

## Async UX and loading states

- Always show a visible loading / placeholder / progress state while network calls or other async processing are in-flight.
- Views should never appear "frozen" while awaiting data; use skeletons, shimmers, or `ProgressView` variants consistent with the design system.

---

## Build and verification after changes

- After making code changes, run a build **and the test suite** before considering the work done. A passing build alone is not sufficient.
- Use the pinned-simulator form in CI and when OS-specific behaviour matters; use the no-OS-pin form for quick local feedback.
- The generic-platform build (no signing) is the minimum check that must pass in environments without a provisioning profile.

```bash
# Build
xcodebuild -scheme [AppScheme] -configuration Debug build

# Run tests on a pinned simulator (preferred – matches CI)
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName],OS=[SimulatorOS]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40

# Run tests on latest available simulator of a given device (no OS pin)
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'platform=iOS Simulator,name=[SimulatorName]' \
  test -only-testing:[TestBundle] 2>&1 | tail -40

# Build without code signing (CI / no provisioning profile)
xcodebuild -scheme [AppScheme] -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build 2>&1

# Lint
swiftlint

# Format
swiftformat .
```

> **Placeholders** – replace before use:
> - `[AppScheme]` – Xcode scheme name (e.g. `MyApp`)
> - `[SimulatorName]` – simulator device name (e.g. `iPhone 16`)
> - `[SimulatorOS]` – OS version string (e.g. `18.4`); omit the `,OS=` clause to pick the latest installed
> - `[TestBundle]` – unit-test target name (e.g. `MyAppTests`)
