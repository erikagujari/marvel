---
name: readme-sync
description: Detect drift between README.md and the pokedex codebase, propose a patch, apply it on confirmation. Diff-gates on signal files vs origin/main; skips the LLM pass entirely when nothing structural changed. Pass --since <ref> to compare against a different base, --report-only to print the diff without applying.
allowed-tools: Bash(git:*), Read, Edit
argument-hint: "[--since <ref>] [--report-only]"
model: sonnet
---

You are checking whether `README.md` is in sync with the current pokedex code state, and if not, proposing a minimal patch.

## PHILOSOPHY

- **Signal-gated.** If no file that the README actually describes has changed since `<base>`, exit immediately without invoking the LLM step. This is the cheap path and it should be the common one.
- **Minimal diffs.** Only change README lines that are factually wrong against the current code. Do not rewrite prose voice, do not add new sections, do not "improve" wording that's still accurate.
- **Never silent-apply.** Always print the proposed diff and ask y/n before editing. The user stays in control.
- **Don't stage, commit, or push.** The skill only edits `README.md`. The caller (`/pr-ready` or the user directly) decides what to do with the resulting working-tree change.

## ARGUMENTS

Parse `$ARGUMENTS` first.

- `--since <ref>`: compare against `<ref>` instead of `origin/main`. Useful for inspecting drift introduced by a specific stretch of history (e.g. `--since HEAD~5`).
- `--report-only`: print the proposed diff and exit. Skip the y/n prompt and the `Edit` step.

## STEP 0 — Resolve base ref

If `--since <ref>` was passed, use that ref verbatim. Otherwise default to `origin/main`:

1. `git fetch origin main --quiet` (best-effort; if it fails, fall back to local `main`).
2. Use `origin/main` as `<base>`.

## STEP 1 — Signal-file gate (skip the LLM if nothing structural changed)

Run:

```
git diff --name-only <base>..HEAD
```

Filter the output to the **signal set** — files that, if changed, could invalidate something README claims:

- `pokedex/pokedex/**/*.swift` — folder layout, MVVM+Router, image cache (README §Architecture, §UI Details)
- `pokedex/pokedex/Data/Services/**` — API endpoints (README §Architecture line about PokéAPI)
- `pokedex/pokedex.xcodeproj/project.pbxproj` — deployment target, scheme name, Xcode version (README §Stack — currently says "Xcode 13" / "iOS 15")
- `.swiftlint.yml` — linting rules (README §Linting)
- `.githooks/**` — pre-commit hook (README §Linting)
- `CLAUDE.md` — README and CLAUDE.md should agree on build/test commands and folder layout

If the filtered set is **empty**: print

```
README in sync (no signal files changed since <base>).
```

and exit. Do not proceed to STEP 2.

## STEP 2 — Drift check

Read `README.md` in full.

For each file in the filtered signal set, `Read` it. If a file is longer than 200 lines, read only the first 200. (`project.pbxproj` is verbose — for that file, also `grep -n IPHONEOS_DEPLOYMENT_TARGET pokedex/pokedex.xcodeproj/project.pbxproj | head -3` to extract the deployment target directly.)

Then walk the README section by section and check each claim against the code you just read:

- **Architecture** — Do the bullets still match the folders under `pokedex/pokedex/`? Is MVVM+Router still the pattern (look for `Router.swift` files)? Is the image cache still CoreData (`Data/Cache/CoreData/`)?
- **UI Details** — Are Home and Detail still wired the way the README describes? Does the Detail still zip `/pokemon/{id}` and `/pokemon-species/{id}`?
- **Testing** — Do the test categories listed still exist under `pokedexTests/`?
- **Stack** — Does "Xcode 13" / "iOS 15" still match the project's deployment target? (Read it from `IPHONEOS_DEPLOYMENT_TARGET`.)
- **Linting** — Does the SwiftLint setup still install via brew + `git config core.hooksPath .githooks`? Does `.githooks/pre-commit` still exist with the soft-fail behavior?

If every claim still matches: print

```
README in sync (LLM pass: NO-OP).
```

and exit.

Otherwise produce a **unified diff** for `README.md` covering only the lines that are factually wrong. Keep changes minimal and surgical.

## STEP 3 — Confirm + apply

Print the proposed diff in a fenced code block:

````
```diff
<unified diff for README.md>
```
````

If `--report-only` was passed: exit here.

Otherwise ask:

```
Apply this README update? (y/n)
```

- On `y`: use `Edit` to apply each hunk to `README.md`. Prefer one `Edit` per hunk to keep failures localized. Confirm with:

  ```
  Applied. README.md now reflects the current code state. The change is unstaged — commit it via /ship or `git add README.md && git commit`.
  ```

- On `n` (or anything other than `y`): print

  ```
  Skipped. README left unchanged.
  ```

  and exit.

## FAILURE MODES

- **`git fetch` fails** (offline, no remote): fall back to local `main` and continue. Note this in STEP 1's output if the gate fires.
- **`<base>` does not exist**: stop with a clear message ("base ref `<base>` not found"). Do not proceed.
- **`Edit` fails on a hunk** (e.g. the README lines have already changed): stop, surface the failed hunk, do not attempt fuzzy retries. The user can re-run after fixing.

Begin by parsing arguments and running STEP 0 now.
