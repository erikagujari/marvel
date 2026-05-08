# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project layout
The Xcode project lives one level below the repo root, inside `pokedex/`:
- Xcode project: `pokedex/pokedex.xcodeproj`
- App sources: `pokedex/pokedex/`
- Tests: `pokedex/pokedexTests/`

Vanilla Xcode project — no SPM `Package.swift`, no CocoaPods, no Carthage, no Makefile, no fastlane. Swift 5.0, iOS deployment target 15.0. Scheme and app target are both `pokedex`; the test target is `pokedexTests`.

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

`PokemonRepositoryProvider.fetchDetail(id:)` zips the detail and species requests via `Publishers.Zip` and merges them into a single `PokemonDetail`.

List-cell artwork is derived from the parsed id, no extra request: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png` (see `Pokemon.artworkURL(for:)`).

## Architecture
MVVM + Router with Combine. Folders under `pokedex/pokedex/` mirror the layers:

- `App/` — UIKit presentation. `Modules/{Home,Detail,Base}` each contain ViewController + ViewModel + Router + UIComposer (constructor-based DI wiring).
- `Domain/` — `UseCases/` (e.g. `FetchPokemonUseCase`, `FetchPokemonDetailUseCase`, `ImageLoaderUseCase`) and domain `Entitites/` (note repo's spelling).
- `Data/` — `Network/` (`HTTPClient` protocol, generic Combine `AnyPublisher` fetch; `APIError`), `Services/` (enum-based `Service` protocol that builds `URLRequest`s with query params), `Repositories/` (e.g. `PokemonRepository` wires network + cache), `Entities/` (DTOs), `Cache/`.

Reactive plumbing uses Combine (`CurrentValueSubject`, `PassthroughSubject`, `AnyPublisher`). When adding a feature, follow the existing module template: add a folder under `App/Modules/`, create matching use cases under `Domain/UseCases/`, and back them with a repository under `Data/Repositories/`.

## Image caching (CoreData)
The image cache uses CoreData (migrated from `NSCache` in commits `d5473ca`, `04d498a`).

- Model: `Data/Cache/CoreData/CoreDataFeed.xcdatamodeld`
- Stack: `CoreDataFeedStore` wraps `NSPersistentContainer` and exposes an `NSManagedObjectContext`.
- Abstraction: `ImageDataStore` protocol (`insert`/`retrieve` keyed by URL path); `CoreDataFeedStore+FeedImageDataLoader` is the concrete implementation.
- Consumer: `ImageLoaderUseCase` caches image bytes by URL path on first fetch and serves subsequent retrievals from CoreData.

## Testing patterns
Pure XCTest — no Quick/Nimble, no snapshot testing. Tests live in `pokedexTests/`:

- **Unit**: `HomeViewModelTests`, `FetchPokemonUseCaseTests`, `FetchPokemonDetailUseCaseTests`, `PokemonRepositoryTests` (+ `+JSONMock` extension), `ImageLoaderUseCaseTests`.
- **Integration** (preferred over UI tests per README): `HomeIntegrationTests`, `DetailIntegrationTests` — drive a real `UIViewController` + `ViewModel` against a stubbed use case.
- **Helpers**: `Helpers.swift` (shared fixtures: `anyPokemonList`, `anyPokemonDetail`, stubs), `XCTestCase+MemoryLeakTracking.swift` — call `trackForMemoryLeaks(_:file:line:)` on each SUT/collaborator at the end of factory methods so leaked references fail the test in `tearDown`.

Stubs are typically closures returning `AnyPublisher<T, Error>` — match this style when adding new tests.
