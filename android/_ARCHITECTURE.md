# [App Name] – Clean Architecture + MVVM

This document describes how **Clean Architecture** and **MVVM** work together in the app, and how **Hilt** (or your chosen DI framework) is used for dependency injection.

> **Template note:** Replace `[App Name]`, all placeholder paths, and all `[...]` tokens with project-specific values before committing this file to the client repository.

---

## Flow of control

```
Screen/Composable (Jetpack Compose) → ViewModel (MVVM) → Use Case (Clean) → Repository (Clean)
```

- **Screen/Composable**: Dumb. Displays UI state and forwards user events to the ViewModel.
- **ViewModel**: Interface adapter. `StateFlow`/`UiState` holder; calls Use Cases; depends on abstractions (interfaces), not concrete types.
- **Use Case (Interactor)**: Application business logic. Depends only on repository (and other domain) abstractions.
- **Repository**: Abstraction (interface) for data. Implementations live in `data/` (Retrofit, Room, DataStore, etc.).

## Dependency rule

Inner layers do not know about outer layers:

- **Domain**: Entities/Models, Repository interfaces, Use Cases. No Android framework types, no Compose, no concrete data sources.
- **Data**: Concrete implementations of repository interfaces (network, persistence, cache, DTOs).
- **Presentation**: ViewModels and Screens/Composables. ViewModels depend on Use Cases (via interfaces or concrete types resolved by DI).

Dependency injection (Hilt) is what allows the app to satisfy the dependency rule: the DI modules wire concrete implementations to interfaces.

---

## Layout

| Module / Folder | Purpose |
|----------------|---------|
| `app/` | Application class, Hilt setup, app-level navigation graph, theme entry point. |
| `core/` | Domain (Entities, Repository interfaces, Use Cases), Data (repository implementations, network, DTOs, persistence), DI (Hilt modules). |
| `design_system/` (or `ui/`) | Reusable Composables, color tokens, typography, spacing, dimension constants from the design source (e.g. Figma). |
| `feature/` | Feature modules: Screens, ViewModels, and per-feature string resources / constants. |

Current application class:
- `app/src/main/java/[package]/[AppName]Application.kt`

---

## App shell architecture (mandatory)

The app shell must follow a single, consistent pattern for post-login layout, navigation, and app-wide communication.

### 1) Root hierarchy and background

- `AppContent` (or `RootScreen`) is the composition root for high-level app state.
- Authenticated flow is rendered in a `Box` with `AppCommonBackground` drawn behind content.
- After login, all authenticated root layers should be edge-to-edge (`WindowCompat.setDecorFitsSystemWindows(window, false)` + Compose inset handling) to prevent status bar / system bar clipping regressions.
- Do not use ad hoc per-screen top-area background hacks for authenticated screens; rely on `AppCommonBackground`.

Current root files:
- `feature/root/ui/RootScreen.kt`
- `feature/root/viewmodel/RootViewModel.kt`

### 2) Navigation model

- Navigation is based on **Jetpack Navigation Compose** with a single `NavHost`.
- Each bottom navigation destination (tab) is a nested navigation graph owning its own back stack.
- All tab back stacks are managed by the root `NavController`; tab state is restored via `saveState = true` / `restoreState = true`.
- Back navigation from shared navigation UI (for example `AppTopBar`) must call `navController.navigateUp()` or a coordinator-level `navigateBack()` method.
- Top bar back button policy:
  - `AppTopBar` defaults to `navigationIcon = null` (no back button).
  - Parent/tab-root screens keep back button hidden by default.
  - Child/pushed screens opt in by passing a `navigationIcon` lambda when needed.
  - When back button is hidden, title remains start-aligned (no leading placeholder gap).

Current coordinator/navigation files:
- `feature/navigation/AppNavHost.kt`
- `feature/navigation/BottomNavItem.kt`

### 3) Shared cross-tab state

- Shared UI/app state is centralized in `AppSharedStateHolder` (a Hilt `@Singleton` ViewModel or state holder).
- Tab selection is owned by `AppSharedStateHolder.selectedTab`.
- Cross-tab features must read/write shared state through `AppSharedStateHolder`, not by reaching into sibling screens or ViewModels.
- On logout, shared app state must be reset (`AppSharedStateHolder.clear()`).

Current shared-state file:
- `feature/navigation/AppSharedStateHolder.kt`

### 4) App-wide events

- App-wide events are published via `AppEventBus` (a `SharedFlow`-backed event channel).
- Do not introduce new app-wide `LocalBroadcastManager` broadcasts or `EventBus` calls for internal feature coordination.
- Event producers emit through typed sealed-class events on `AppEventBus` (for example auth-state and preferences changes).
- Event consumers collect via injected `AppEventBus` dependency inside their ViewModel's `viewModelScope`.

Current event file:
- `feature/navigation/AppEventBus.kt`

### 5) DI and ownership rules for shell types

- `AppEventBus`, `AppSharedStateHolder`, and the root `NavController` provider are app-wide singletons registered in `core/di/AppModule.kt` (or `NavigationModule.kt`).
- ViewModels that need app-wide coordination must receive these dependencies via Hilt constructor injection.
- Avoid direct cross-feature calls such as manually refreshing unrelated ViewModels from Composables; prefer event emission + collector reaction.
- Logout/login transitions should be driven by auth events and `RootViewModel` state collection.

---

## Navigation migration plan (feature-owned graph)

Goal: move from a single flat `NavHost` to **feature-owned nested navigation graphs** with reusable top bar components.

Migration steps (repeat per feature in order):
1. Create `<FeatureName>NavGraph.kt` inside `feature/<featurename>/navigation/`.
2. Extract the nested graph via `navigation(startDestination = ..., route = ...)` inside `AppNavHost`.
3. Attach the shared header via `AppTopBar(title = ..., onBack = ...)` at the screen level, not at the graph root.
4. Wire back button actions to `navController.navigateUp()` (or a coordinator method).
5. Keep using a consistent trailing action pattern (e.g. a settings icon or overflow menu) within each feature graph.
6. Remove legacy flat routes for the migrated feature from the root `NavHost`.

Final cleanup after all features are migrated:
- Ensure `AppNavHost` only composes nested graph functions as leaves.
- Keep `AppSharedStateHolder` and the root `NavController` as the single sources of truth for cross-feature navigation state.

---

## API and environment configuration

- **Base URL**: Centralised in `core/data/network/ApiConfig.kt`. Use a `BuildConfig` field or a sealed `Environment` class (`.Dev` / `.Staging` / `.Prod`) to switch:
  - **Dev**: `http://10.0.2.2:[port]` (Android emulator localhost alias)
  - **Staging**: `https://staging-api.[domain]`
  - **Prod**: `https://api.[domain]`
- **Current environment**: `ApiConfig.BASE_URL` is resolved from `BuildConfig.BASE_URL`, set per build variant in `build.gradle.kts`. All network code uses this constant so a single place controls the backend.
- **Adding a new environment**: Add a build variant (or flavor dimension) and set `BASE_URL` in that variant's `buildConfigField`; no code changes needed outside `build.gradle.kts`.

---

## Data layer (network, DTOs, repositories)

- **Network**: `ApiService` (Retrofit interface) performs HTTP requests. A single `Retrofit` instance is provided by Hilt with the configured base URL and default headers (auth interceptor, logging interceptor). Repositories depend on `ApiService`, not `OkHttpClient` or `Retrofit` directly.
- **Endpoints**: All Retrofit `@GET`/`@POST`/etc. annotations live in `core/data/network/ApiService.kt`. No base URL here; it is set on the `Retrofit.Builder`.
- **DTOs**: Request/response shapes for the API live in `core/data/dto/`. Use Kotlin data classes with `@SerialName` (kotlinx.serialization) or `@SerializedName` (Gson). Domain stays free of API details; repositories map between domain models and DTOs.
- **Repositories**: Implement domain repository interfaces in `core/data/repository/`. They take `ApiService` (and optionally a `Dao`) injected via Hilt, call endpoints, parse DTOs, and return domain models or `Result<T>`. Throw or wrap domain errors; do not expose DTOs to Use Cases or ViewModels.
- **Local persistence**: Room `Dao` interfaces live in `core/data/local/`. Entities (Room `@Entity`) are separate from domain models; mappers in the repository handle conversion.

---

## Adding a new feature

1. **Domain model** (if needed): `core/domain/model/`.
2. **Repository interface**: `core/domain/repository/`.
3. **Use Case**: `core/domain/usecase/` – depends on repository interface only.
4. **DTOs** (if API): `core/data/dto/` – request/response types; keep API shape in the data layer.
5. **Endpoint** (if API): Add a Retrofit method in `core/data/network/ApiService.kt`.
6. **Repository implementation**: `core/data/repository/` – inject `ApiService` (and/or `Dao`), call endpoint, map DTOs to domain models.
7. **Register in DI**: Add `@Binds` / `@Provides` in the relevant Hilt module (e.g. `core/di/RepositoryModule.kt`, `core/di/UseCaseModule.kt`) – bind interface to implementation.
8. **ViewModel**: `feature/<featurename>/viewmodel/<Feature>ViewModel.kt` – `@HiltViewModel`; init takes use case via `@Inject constructor`.
9. **Screen**: `feature/<featurename>/ui/<Feature>Screen.kt` – stateless Composable receiving `uiState` and event lambdas; `hiltViewModel()` resolves the ViewModel at the call site.
10. **Strings / constants**: `feature/<featurename>/res/strings.xml` (or a `Strings.kt` constant object) and a `Constants.kt` for non-user-facing values.

---

## Design system

- **Colors**: `design_system/Color.kt` – design token values (brand palette, semantic colors). Use `MaterialTheme.colorScheme` for adaptive light/dark support; define a custom `[AppName]ColorScheme` if Material tokens are insufficient.
- **Brand colours**: Define the raw brand palette in `Color.kt` and expose only semantic names (e.g. `AppColors.Primary`) to feature code.
- **Gradients**: Define named `Brush` presets (e.g. `AppBrush.backgroundGradient`) in `design_system/Gradient.kt` and use them consistently across the app.
- **Typography**: `design_system/Type.kt` – text styles sourced from the design file (e.g. matching Figma type scale). Extend or override `MaterialTheme.typography` as needed.
- **Dimensions / Spacing**: `design_system/Spacing.kt` – named spacing and radius tokens; avoid hardcoded `dp` values in feature Composables.

Source: [Link to Figma or design file]

---

## Async UX and loading states

- Always show a visible loading / placeholder / progress state while network calls or other async processing are in-flight.
- Composables should never appear "frozen" while awaiting data; use `CircularProgressIndicator`, skeleton shimmer layouts, or placeholder patterns consistent with the design system.
- Represent loading, success, and error as explicit states in a sealed `UiState` class owned by the ViewModel.

---

## Build and verification after changes

- After making code changes, run a build **and the test suite** before considering the work done. A passing build alone is not sufficient.
- Run unit tests with `./gradlew testDebugUnitTest` after every change. Run module-scoped tests (`./gradlew :[module]:testDebugUnitTest`) for faster feedback during active development.
- Run instrumented tests (`./gradlew connectedDebugAndroidTest`) when changes affect UI, navigation, or platform integrations that cannot be covered by unit tests alone.

```bash
# Build debug APK
./gradlew assembleDebug

# Run all unit tests (debug variant)
./gradlew testDebugUnitTest

# Run unit tests for a specific module
./gradlew :[module]:testDebugUnitTest

# Run instrumented tests on connected device or emulator
./gradlew connectedDebugAndroidTest

# Run instrumented tests for a specific module
./gradlew :[module]:connectedDebugAndroidTest

# Lint
./gradlew lint

# Detekt (if configured)
./gradlew detekt

# Ktlint format (if configured)
./gradlew ktlintFormat
```

> **Placeholder** – replace `[module]` with the Gradle module name (e.g. `feature:home`, `core:data`).
