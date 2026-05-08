---
name: pr-ready
description: Local build+test+code-review gate for the pokedex repo. Runs xcodebuild on the iPhone 17 simulator, invokes /code-review on the diff, then opens a PR via gh. No Jira, no Bazel. Pass --dry-run to skip push and PR creation, --no-review to skip the code-review pass.
allowed-tools: Bash(xcodebuild:*), Bash(git:*), Bash(gh:*), Bash(swiftlint:*), Read, Edit, Skill, Agent, TaskCreate, TaskUpdate
argument-hint: "[--dry-run] [--no-review]"
model: sonnet
---

You are gating a pokedex iOS branch before opening a PR. The working tree is clean (`/ship` should have committed everything); your job is to run build+test, optionally run a code-review pass, push the branch, and open a PR via `gh`.

This is the **project-local** pr-ready (lives at `.claude/skills/pr-ready/SKILL.md` in this repo). It is intentionally simpler than the global `~/.claude/skills/pr-ready/`: no Bazel/`tente`, no Marito-CR re-review loop, no Jira transitions, no auto-fix budget.

## PHILOSOPHY

- **Linear, no auto-fix loop.** If build or test fails, surface the output and stop — the human decides whether to fix in this branch or elsewhere. The global `/pr-ready` has a 3-commit budget for auto-fixes; this fork doesn't.
- **Plain PR title and body.** No team template. Title from the most-impactful commit subject, body summarises the commits.
- **`gh` for PR creation, not the GitHub web UI.** Repeatable from CLI.
- **Never push to a protected branch.** Hard guard at preflight.

## ARGUMENTS

Parse `$ARGUMENTS` first.

- `--dry-run`: run preflight + build + test + (optionally) code-review, but **skip push and PR creation**. Just print what would happen.
- `--no-review`: skip the code-review pass. Default is to run it.

## STEP 0 — Preflight

1. **Branch guard**: `BRANCH_NAME="$(git branch --show-current)"`. If empty (detached HEAD) or matches `main`, `master`, `release/*`, `hotfix/*`, stop.
2. **Working tree must be clean**: `git status --porcelain`. If non-empty, stop and suggest invoking `/ship` first.
3. **Branch must be ahead of `origin/main`**:
   - `git fetch origin main --quiet`
   - `git rev-list --count origin/main..HEAD` — must be ≥ 1. If 0, stop with "nothing to PR".
4. **Existing PR check**: `gh pr view --json url,state 2>/dev/null`. If a PR is already open for this branch, surface its URL and ask the user whether to continue (which will refresh checks but not re-create the PR) or abort.
5. Create a task list via `TaskCreate`:
   - "Build + test"
   - "Code review" (omit if `--no-review`)
   - "README sync"
   - "Push branch"
   - "Open PR" (omit if `--dry-run`)
6. **Fire the README-sync subagent in parallel** (do **not** await it; build+test starts immediately afterwards). The subagent runs in its own context so the signal-file reads stay out of this thread:

   ```
   Agent(
     subagent_type: "general-purpose",
     description: "README drift check",
     run_in_background: true,
     prompt: <see template below>
   )
   ```

   Save the agent's id/name — you'll collect its result in STEP 2.5.

   **Prompt template** (self-contained — the subagent has no session context):

   > You are a README-drift detector for the pokedex iOS repo at `/Users/erik.agujari/Projects/marvel`. Determine whether `README.md` still matches reality, and if not, propose a minimal patch.
   >
   > 1. Run `git fetch origin main --quiet` then list changed files with `git diff --name-only origin/main..HEAD`.
   > 2. Filter to the **signal set**: `pokedex/pokedex/**/*.swift`, `pokedex/pokedex/Data/Services/**`, `pokedex/pokedex.xcodeproj/project.pbxproj`, `.swiftlint.yml`, `.githooks/**`, `CLAUDE.md`.
   > 3. If the filtered set is empty, return exactly: `STATUS: IN-SYNC (no signal files changed)` and stop.
   > 4. Otherwise read `README.md` in full, then read each changed signal file (truncate >200 lines; for `project.pbxproj`, just `grep -n IPHONEOS_DEPLOYMENT_TARGET pokedex/pokedex.xcodeproj/project.pbxproj | head -3`).
   > 5. Walk README sections (Architecture, UI Details, Testing, Stack, Linting). For each, check whether the current claim still matches the code. Common drift: "Xcode 13"/"iOS 15" lines vs `IPHONEOS_DEPLOYMENT_TARGET`; folder bullets vs actual subfolders; PokéAPI endpoint descriptions vs `Data/Services/` enum cases; SwiftLint setup vs `.swiftlint.yml` and `.githooks/pre-commit`; build/test commands vs `CLAUDE.md`.
   > 6. If everything still matches, return exactly: `STATUS: NO-OP (README accurate)`.
   > 7. Otherwise return:
   >
   >    ```
   >    STATUS: DRIFT
   >    SIGNALS_CHANGED: <comma-separated list of changed signal files>
   >    DIFF:
   >    ```diff
   >    <unified diff against README.md, minimal hunks only>
   >    ```
   >    ```
   >
   > Do not write to any file. Do not stage, commit, or push. Return only the verdict described above.

## STEP 1 — Build + test

Run the test suite on the iPhone 17 simulator (matches `CLAUDE.md`):

```
xcodebuild -project pokedex/pokedex.xcodeproj -scheme pokedex \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

- On success: continue.
- On failure: **stop**. Surface the test output verbatim (the failing `module::test` identifiers and the assertion messages). Do not attempt auto-fix. Leave commits in place. Update the task list to mark the step failed and exit.

If you suspect simulator flakiness (e.g. a single test failed once that has historically been stable), you may retry the failing tests **once** via `-only-testing:` before declaring failure. Don't loop.

## STEP 2 — Code review (skip with `--no-review`)

Invoke the global `/code-review` skill via `Skill`. It is generic and reads the local diff against `main`. Surface its findings to the user.

- If the review reports **only nits or no issues**: continue.
- If the review reports a **likely bug or correctness issue**: stop, surface the finding, and ask the user whether to push anyway, fix in this branch (in which case they'd re-run `/ship` then `/pr-ready`), or abort.

## STEP 2.5 — README sync (soft gate)

Collect the README-sync subagent result that was kicked off in STEP 0. If it's still running, wait for it now — by this point build+test and code-review have both finished, so the subagent should be done or close to it.

Branch on the `STATUS:` line at the top of its output:

- `STATUS: IN-SYNC (...)` or `STATUS: NO-OP (...)` — continue silently. Mark the "README sync" task completed; record the outcome ("in-sync" / "no-op") for STEP 5.

- `STATUS: DRIFT` — the subagent returned a proposed `README.md` diff. Surface it to the user:

  1. Print the `SIGNALS_CHANGED:` line and the ```diff block from the subagent's output.
  2. Ask: `Apply this README update before pushing? (y/n)`
     - On `y`: apply each hunk via `Edit` to `README.md`, then:
       ```
       git add README.md
       git commit -m "docs: sync README to current code state"
       ```
       The new commit will be included in the push. Record outcome "applied" for STEP 5.
     - On `n` (or anything else): leave `README.md` untouched and continue. Record outcome "declined" for STEP 5.

- Subagent failed, timed out, or produced unparseable output: record outcome "errored" for STEP 5 and continue. **Do not block.** This is a soft gate; a flaky drift check must not stop a PR.

Mark the "README sync" task completed regardless of outcome.

## STEP 3 — Push

If `--dry-run`: print "would push `<branch>` to origin" and stop here.

Otherwise:
- If upstream is unset (`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null` fails): `git push -u origin <BRANCH_NAME>`.
- Else: `git push`.
- If push is rejected as non-fast-forward, **stop** and report. Do not force-push without explicit user approval.

## STEP 4 — Open PR

If `--dry-run`: print the title/body that would be used and stop.

Build the PR title and body:

- **Title**: subject of the most-impactful commit on the branch. Heuristic: the longest-prefix `prod+unit` commit (i.e. `<module>: <subject>`); if none, fall back to the first commit's subject. ≤72 chars.
- **Body**: ```
  ## Summary
  <one-or-two-sentence synthesis of what this branch does, drawn from the commit bodies and the conversation context>

  ## Commits
  <bulleted list: `git log --pretty=format:'- %s' origin/main..HEAD`>

  ## Test plan
  - [ ] xcodebuild test passes on iPhone 17 simulator
  - [ ] <any feature-specific manual check inferred from the diff>
  ```

Run:

```
gh pr create --base main --head <BRANCH_NAME> \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body>
EOF
)"
```

- On success: surface the PR URL returned by `gh`.
- On failure: surface stderr verbatim. Do not retry blindly.

## STEP 5 — Report

Print:
- The PR URL (or "dry-run, no PR created").
- The list of commits that landed in this run (`git log --oneline origin/main..HEAD`).
- A note if `--no-review` was used (so the user remembers they skipped that gate).
- README-sync outcome: `in-sync`, `no-op`, `applied` (and the docs commit hash), `declined` (drift surfaced but user said no), or `errored` (subagent failed — drift state unknown).

Stop. The user's responsibility from here is to review the PR in the browser.

## FAILURE MODES

- **Build/test fails**: stop at Step 1, no push. Commits are still in place locally — the user can fix and re-run.
- **Code review reports a likely bug**: stop at Step 2, no push. Same recovery path.
- **Push rejected**: stop at Step 3. The user resolves manually (rebase or force-push with-lease — both require their explicit approval).
- **`gh pr create` fails**: stop at Step 4. The branch is already pushed; the user can re-attempt manually.
- **PR already open for branch**: surfaced in preflight; user decides whether to refresh checks (no-op here, but build+test ran) or abort.

Begin by parsing arguments and running Step 0 now.
