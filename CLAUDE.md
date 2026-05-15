# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project layout
The Xcode project lives one level below the repo root, inside `pokedex/`:
- Xcode project: `pokedex/pokedex.xcodeproj`
- App sources: `pokedex/pokedex/`
- Tests: `pokedex/pokedexTests/`

Vanilla Xcode project — no SPM `Package.swift`, no CocoaPods, no Carthage, no Makefile, no fastlane. Swift 6.0, iOS deployment target 17.0. Scheme and app target are both `pokedex`; the test target is `pokedexTests`.

## Build & test
All `xcodebuild` invocations must reference the nested project path:

```bash
# Build (Debug)
xcodebuild -project pokedex/pokedex.xcodeproj -scheme pokedex -configuration Debug build

# Run all tests on a simulator
xcodebuild -project pokedex/pokedex.xcodeproj -scheme pokedex \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a single test class or method
xcodebuild -project pokedex/pokedex.xcodeproj -scheme pokedex \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:pokedexTests/HomeViewModelTests test

# Single method
... -only-testing:pokedexTests/HomeViewModelTests/test_fetchInitialCharacters_loadsCharactersOnUseCaseSuccess test
```

## API
Backed by the public [PokéAPI](https://pokeapi.co/docs/v2). No auth, no API keys, HTTPS-only. Endpoints used:
- `GET /api/v2/pokemon?offset=N&limit=20` — paginated list (`{name, url}` items; `id` parsed from `url`).
- `GET /api/v2/pokemon/{id}` — sprite + types.
- `GET /api/v2/pokemon-species/{id}` — `flavor_text_entries` (English entry → `description`).

`PokemonRepositoryProvider.fetchDetail(id:)` zips the detail and species requests with `async let` and merges them into a single `PokemonDetail`.

List-cell artwork is derived from the parsed id, no extra request: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png` (see `Pokemon.artworkURL(for:)`).

## Architecture
SwiftUI + MVVM with `@Observable` view models and a single `AppCoordinator` driving `NavigationStack`. Folders under `pokedex/pokedex/` mirror the layers:

- `PokedexApp.swift` — `@main App` entry. Owns the `AppCoordinator` via `@State`, wraps the home in `NavigationStack(path: $coordinator.path)` and binds `.navigationDestination(for: Route.self)` to `DetailUIComposer.compose`.
- `App/` — SwiftUI presentation.
  - `AppCoordinator.swift` — `@Observable @MainActor` coordinator owning `var path: [Route]` and `showDetail(id:)` / `pop()`. Replaces the per-screen `Router` types.
  - `Modules/{Home,Detail,Base}` — each module has a SwiftUI `View`, an `@Observable @MainActor` ViewModel + protocol, and a `UIComposer` static factory returning `some View`.
  - `Views/CachedAsyncImage.swift` — wraps `ImageLoaderUseCase` so SwiftUI views read images through the CoreData-backed cache. **Do not use stock `AsyncImage` — it bypasses the cache.**
- `Domain/` — `UseCases/` (e.g. `FetchPokemonUseCase`, `FetchPokemonDetailUseCase`, `ImageLoaderUseCase`, all `async throws` + `Sendable`) and domain `Entitites/` (note repo's spelling).
- `Data/` — `Network/` (`HTTPClient` protocol, `async throws` based; `APIError`), `Services/` (enum-based `Service` protocol that builds `URLRequest`s with query params), `Repositories/` (e.g. `PokemonRepository` wires network + cache), `Entities/` (DTOs), `Cache/`.

All ViewModels are `@Observable @MainActor`; views consume them via `@Bindable`. SwiftUI's automatic dependency tracking replaces the UIKit-era `withObservationTracking` re-registration. When adding a feature, follow the existing module template: add a folder under `App/Modules/`, expose an `@Observable @MainActor` VM + protocol, write a SwiftUI `View<VM>`, wire it in a `UIComposer.compose(...) -> some View`, and add a `Route` case to `AppCoordinator`.

## Image caching (CoreData)
The image cache uses CoreData (migrated from `NSCache` in commits `d5473ca`, `04d498a`).

- Model: `Data/Cache/CoreData/CoreDataFeed.xcdatamodeld`
- Stack: `CoreDataFeedStore` wraps `NSPersistentContainer` and exposes an `NSManagedObjectContext`.
- Abstraction: `ImageDataStore` protocol (`insert`/`retrieve` keyed by URL path); `CoreDataFeedStore+FeedImageDataLoader` is the concrete implementation.
- Consumer: `ImageLoaderUseCase` caches image bytes by URL path on first fetch and serves subsequent retrievals from CoreData.

## Testing patterns
Pure XCTest — no Quick/Nimble, no snapshot testing, no ViewInspector. Tests live in `pokedexTests/`:

- **Unit**: `HomeViewModelTests`, `FetchPokemonUseCaseTests`, `FetchPokemonDetailUseCaseTests`, `PokemonRepositoryTests` (+ `+JSONMock` extension), `ImageLoaderUseCaseTests`.
- **Integration** (preferred over UI tests per README): `HomeIntegrationTests`, `DetailIntegrationTests` — host the SwiftUI view in a `UIHostingController`, mount it in a key `UIWindow` so SwiftUI's `.task` and `onAppear` fire, then assert against the `@Observable` ViewModel state. Use the `mountInWindow(_:)` helper, which registers its own teardown block to detach the controller cleanly.
- **Helpers**: `Helpers.swift` (shared fixtures: `anyPokemonList`, `anyPokemonDetail`, `waitFor`, `mountInWindow`, stubs), `XCTestCase+MemoryLeakTracking.swift` — call `trackForMemoryLeaks(_:file:line:)` on each SUT/collaborator at the end of factory methods so leaked references fail the test in `tearDown`. Memory-leak tracking applies to the `UIHostingController`, the `@Observable` ViewModel, and the `AppCoordinator`.

Stubs are typically closures returning `Result<T, APIError>` exposed via `async throws` — match this style when adding new tests.
