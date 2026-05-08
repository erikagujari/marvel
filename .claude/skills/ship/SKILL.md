---
name: ship
description: Split this repo's dirty working tree into logical commits (prod+unit / integration / config), then chain into the local /pr-ready. Plain subjects, no ticket prefix. Pass --single to skip splitting, --dry-run to preview, --no-pr-ready to commit without chaining.
allowed-tools: Bash(git:*), Bash(swiftlint:*), Read, Skill, TaskCreate, TaskUpdate
argument-hint: "[--single] [--dry-run] [--no-pr-ready]"
model: sonnet
---

You are preparing the pokedex iOS branch for shipping. The working tree is dirty; your job is to turn it into a clean, well-grouped commit history and then hand off to the local `/pr-ready`.

This is the **project-local** ship skill (lives at `.claude/skills/ship/SKILL.md` in this repo). It is intentionally simpler than the global `~/.claude/skills/ship/`: no Bazel, no Jira, no ticket-prefix parsing, no snapshot bucket, no asset-registration enum.

## PHILOSOPHY

- **Split by concern, not by file.** Production logic, integration tests, and build config each get their own commit so the diff reads cleanly.
- **Don't over-split.** A single-bucket diff is one commit — fall through to `--single` behavior automatically.
- **Always preview.** Splitting is a structural decision; the user sees the plan and confirms before any commit lands.
- **Pair production code with its unit tests.** A commit whose `.swift` change is unaccompanied by its existing `*Tests.swift` change would fail tests in isolation. Coverage gaps (no test exists yet) are `/pr-ready`'s problem, not ours.
- **Plain commit subjects.** No ticket prefix — match existing repo history (`fix duplication on caching images`, `add FetchCharacterDetailUseCaseTests`).
- **No `Co-Authored-By` line.** This repo's history doesn't use one and the user's git workflow forbids it.
- **Lint before each commit**: `swiftlint --fix` on staged `.swift` paths.
- **Never `git add -A` or `git add .`**: stage the explicit paths for the current group only.
- **Never `--no-verify`**: respect the `.githooks/pre-commit` hook.

## STATE

| Variable | Set by | Read by |
|---|---|---|
| `BRANCH_NAME` | Step 0 | hand-off |
| `GROUPS` | Step 2 | plan prompt, Step 4 commit loop |
| `EXCLUDED_PATHS` | Step 0 | hard-skip during staging |

## ARGUMENTS

Parse `$ARGUMENTS` first.

- `--single`: do not split. One commit covering all non-excluded paths. Still asks for the message.
- `--dry-run`: print the proposed plan and stop. No commits, no `/pr-ready` hand-off.
- `--no-pr-ready`: commit (split or single) but exit before invoking `/pr-ready`.

`--dry-run` wins over `--no-pr-ready` if both are passed.

## STEP 0 — Preflight

1. **Protected-branch guard**: `BRANCH_NAME="$(git branch --show-current)"`. If empty (detached HEAD) or matches `main`, `master`, `release/*`, `hotfix/*`, stop. This skill commits and would push to a release line via `/pr-ready`.
2. **Working tree must be dirty**: `git status --porcelain`. If empty, stop and suggest invoking `/pr-ready` directly — there's nothing to commit.
3. **Compute `EXCLUDED_PATHS`**: any path matching `.env*`, `*.pem`, `credentials*`, `*.p12`, `*.mobileprovision`, `.claude/settings.local.json`, `.claude/scheduled_tasks.lock`. Surface them to the user as "will not be staged" but do not stop.
4. Create a task list via `TaskCreate`:
   - "Classify diff"
   - "Propose split"
   - "Confirm plan"
   - "Commit groups"
   - "Hand off to /pr-ready" (omit if `--no-pr-ready` or `--dry-run`)

## STEP 1 — Enumerate the diff

Collect every dirty path with explicit status:

- Tracked changes: `git diff --name-status HEAD`
- Untracked: `git ls-files --others --exclude-standard`

For untracked directories that show up as a single line in `git status --porcelain` (e.g. `*.imageset/`, `*.xcdatamodel/`), expand to the contained files via `git ls-files --others --exclude-standard <dir>` so the staging step can list explicit paths.

Drop any `EXCLUDED_PATHS`. The result is the working set.

## STEP 2 — Classify and group

### Classification table

Apply rules in order — first match wins:

| Bucket | Match rules |
|---|---|
| `integration` | path under `pokedex/pokedexTests/**/*IntegrationTests.swift` |
| `config` | `.swiftlint.yml`, `.githooks/**`, `pokedex/pokedex/Info.plist`, `*.storyboard`, `Assets.xcassets/**`, `*.xcdatamodel*/**`, `*.xcodeproj/**`, `*.xcworkspace/**`, `*.xcscheme`, `*.entitlements`, `*.plist` |
| `prod+unit` | any `.swift` under `pokedex/pokedex/` (production), **plus** its paired `*Tests.swift` under `pokedex/pokedexTests/` if both touched |
| `misc` | anything unmatched |

**Pairing logic for `prod+unit`**: a production file `<path>/<X>.swift` pairs with `pokedex/pokedexTests/<X>Tests.swift` (or `<X>Spec.swift` as a defensive secondary match). If only the production side is touched, it still goes to `prod+unit`; the missing test is `/pr-ready`'s concern. If only the test side is touched (test-only refactor), include it in `prod+unit` for the same module.

### Module derivation (for `prod+unit`)

- `pokedex/pokedex/App/Modules/<M>/...` → module `<M>` (currently `Home`, `Detail`, `Base`).
- `pokedex/pokedex/Domain/UseCases/<X>UseCase.swift` → module derived from the use-case stem (e.g. `FetchPokemonUseCase` → `Domain`).
- `pokedex/pokedex/Data/...` → module `Data`.
- Anything else under `pokedex/pokedex/` → top-level child folder name (`App`, `Domain`, `Data`).

### Grouping into commits

| Bucket | Splitting axis |
|---|---|
| `prod+unit` | one commit **per module** — pair each prod file with its test file in the same group |
| `integration` | one commit per integration test file |
| `config` | one commit total — never folded into other buckets |
| `misc` | one commit, surfaced for user review |

If after grouping there is exactly one group, fall through to `--single` behavior automatically — don't render a "split" UI for a single commit.

## STEP 3 — Propose plan and confirm

Render the plan compactly. Each group is numbered and goes straight to the commit subject — do **not** prefix the entry with a `<bucket> · <module>` header line; that classification is internal to the splitter and would look like part of the commit message. Example:

```
Proposed split (3 commits):

1. Home: cache pokemon images by URL path
   M pokedex/pokedex/App/Modules/Home/HomeViewModel.swift
   M pokedex/pokedexTests/HomeViewModelTests.swift

2. DetailIntegrationTests: cover species flavor-text fallback
   M pokedex/pokedexTests/DetailIntegrationTests.swift

3. swiftlint: relax line_length for generated mocks
   M .swiftlint.yml

Excluded (will not be staged): .claude/settings.local.json

Reply with: ok | edit <N> | merge <N>+<M>[+...] | single | abort
```

### Subject templates (no ticket prefix)

- `prod+unit`: `<module>: <inferred summary>` — verb derived from diff (added function → "Add", changed signature/body → "Update" or a more descriptive verb, deleted → "Remove"). E.g. `Home: cache pokemon images by URL path`.
- `integration`: `<test-class>: <inferred summary>`. E.g. `HomeIntegrationTests: cover empty list state`.
- `config`: `<area>: <inferred summary>` where `<area>` is `swiftlint`, `xcodeproj`, `assets`, `coredata`, `info.plist`, `githooks`, etc.
- `misc`: `chore: <inferred summary>` and flag for the user.

Inference draws on conversation context first (the *why*), then on the diff (the *what*). Keep subjects ≤72 chars; if inference is shaky, use the bucket fallback and let the user `edit`.

### Body

Two or three lines explaining *why* the change exists — pulled from conversation context (the bug being fixed, the feature being added, the refactor's motivation). If conversation context is thin, write a one-line body from the diff and flag it during `edit` so the user can enrich it.

### User-reply verbs

- `ok` → proceed to Step 4 with the plan as-is.
- `edit <N>` → re-prompt for commit message of group N (subject + body), then re-render plan.
- `merge <N>+<M>[+...]` → fold listed groups into one commit; regenerate combined message; re-render plan. Warn if merging across incompatible buckets (e.g. `config` + `integration`) but allow it.
- `single` → collapse all groups into one commit, prompt once for message.
- `abort` → exit, working tree untouched.

`--dry-run` exits here after rendering the plan once. No prompt.

## STEP 4 — Commit each group

For each group, in declared order:

1. **Stage explicit paths**: `git add <path1> <path2> ...`. Never `git add -A` or `git add .`. For directory entries (e.g. `*.imageset/`, `*.xcdatamodel/`), add the directory path (it's an explicit path, not a wildcard).
2. **Lint staged Swift**: collect staged `.swift` paths via `git diff --staged --name-only --diff-filter=ACM -- '*.swift'`, run `swiftlint --fix --config .swiftlint.yml` against them. Re-stage any auto-fixed paths.
3. **Commit**: `git commit -m "$(cat <<'EOF' ... EOF)"` with the group's subject and body. **No `Co-Authored-By` line.** No `--no-verify`.
4. **On pre-commit hook failure**: surface the hook output, then attempt one *mechanical* retry within the same group. The retry is allowed to: re-run `swiftlint --fix` against the group's staged paths, restage any auto-fixed files, and retry the commit. The retry is **not** allowed to: make LLM source edits, touch unstaged files, or modify files outside the current group. If the hook fails for any non-mechanical reason (or fails again after the mechanical retry), stop, leave prior groups' commits in place, surface the hook output verbatim, and report which group is stuck. Never `--no-verify`.
5. **Update task list** to reflect commit progress.

After all groups commit, verify the working tree is empty: `git status --porcelain` (excluding `EXCLUDED_PATHS`). If non-empty, classification missed something — stop and report the orphan paths. Do **not** chain into `/pr-ready` with a dirty tree.

## STEP 5 — Hand off

If `--no-pr-ready` or `--dry-run`: report the new commits (`git log --oneline ORIG_HEAD..HEAD`) and stop.

Otherwise: invoke `/pr-ready` via `Skill` with no arguments. Its preflight will succeed because the tree is now clean and ahead of `main`, and it owns build/test, code-review, push, and `gh pr create` from there.

## FAILURE & ESCAPE HATCHES

- **`misc` bucket non-empty**: render its paths in the plan and ask the user how to handle (move into another group, leave as its own commit, or abort). Do not silently bucket.
- **Single-file diff or single-bucket diff**: skip the plan UI; treat as `--single` and prompt only for the message.
- **Pre-commit hook fails twice on same group**: stop. Prior commits stay. Report the failing group's path list and the hook output.
- **Pairing produces an unmerged orphan** (e.g. a `*Tests.swift` change with no corresponding production change): include it in `prod+unit` for the same module if one exists; otherwise put it in its own commit and flag it — likely a test-only refactor that the user should review. Note: substring-based pairing (`X.swift ↔ <X>Tests.swift`) breaks under renames where prod and test names diverge; the test lands in its own commit and is flagged here — there is no automatic recovery.
- **Tree dirty after Step 4**: do not chain into `/pr-ready`. Report orphan paths so the user can decide whether they were meant to be excluded or whether classification has a gap.
- **User picks `merge` across incompatible buckets**: allow but warn. They know their diff better than the classifier.

Begin by parsing arguments and running Step 0 now.
