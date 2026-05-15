# Pokédex App: this app fetches a list of Pokémon and a detail of each of them.


## Architecture Details:
* Folder's distribution is: App(UI), Domain(UseCases), Data(Repositories and Network layer)
* UI design pattern is SwiftUI + MVVM with `@Observable` `@MainActor` view models and a single `AppCoordinator` driving `NavigationStack`. `UIComposer` factories return `some View` and wire dependencies.
* Async/await + `@Observable` replace Combine for both network requests and view-state bindings; `@MainActor` covers UI thread safety.
* PokéAPI is HTTPS-only and requires no auth, so the app needs no API keys and no `NSAppTransportSecurity` exceptions.
* There is a basic CoreData usage for cached image retrieval. Once fetching an image from a url path it is cached for future retrievals.

## UI Details:
* **Home** contains a SwiftUI `List` which displays rows containing each Pokémon received from Network. There is no Cache System for failure case at the moment, later on a CoreData cache based will be implemented.
* Once getting to the last item displayed on the list, more items are fetched and later on displayed.
* Rows displayed on home contain an image and a title. Once tapping into one of them a detail is shown.

* **Detail** contains an image, a title, a description and a list of types for the Pokémon selected. The detail screen issues two parallel PokéAPI requests (`/pokemon/{id}` for name/sprite/types and `/pokemon-species/{id}` for English flavor text) and zips them with `async let` into a single domain model.


## Testing:
There is the existence of the unit tests and integration tests, the latter in favor of slower UI tests.

* Unit tests coverage is on view models, use cases, repositories and network layer.
* Integration tests host the SwiftUI view in a `UIHostingController`, mount it in a key `UIWindow` (so `.task`/`onAppear` fire), and assert against the `@Observable` view model state with a stubbed use case.


## Stack:
* Xcode 26
* iOS 17

### API: [PokéAPI](https://pokeapi.co/docs/v2)


## Linting:
The project uses [SwiftLint](https://github.com/realm/SwiftLint) for static analysis. The configuration lives at `.swiftlint.yml` and runs in two places: as an Xcode Run Script build phase on the `pokedex` target (warnings appear inline in the Issue navigator on every build) and as a git pre-commit hook (lints staged Swift files before each commit). Both invocations soft-fail with a `warning:` if SwiftLint is not installed, so the project still builds and commits without it.

One-time setup on a fresh machine:

```bash
brew install swiftlint              # install the linter
git config core.hooksPath .githooks # activate the tracked pre-commit hook
```

Tweak rules in `.swiftlint.yml`. Run `swiftlint --fix` from the repo root to autocorrect the rules that support it.
