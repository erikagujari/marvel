---
name: pr-ready
description: Local build+test+code-review gate for the pokedex repo. Runs xcodebuild on the iPhone 17 simulator, invokes /code-review on the diff, then opens a PR via gh. No Jira, no Bazel. Pass --dry-run to skip push and PR creation, --no-review to skip the code-review pass.
allowed-tools: Bash(xcodebuild:*), Bash(git:*), Bash(gh:*), Bash(swiftlint:*), Read, Skill, TaskCreate, TaskUpdate
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
   - "Push branch"
   - "Open PR" (omit if `--dry-run`)

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

Stop. The user's responsibility from here is to review the PR in the browser.

## FAILURE MODES

- **Build/test fails**: stop at Step 1, no push. Commits are still in place locally — the user can fix and re-run.
- **Code review reports a likely bug**: stop at Step 2, no push. Same recovery path.
- **Push rejected**: stop at Step 3. The user resolves manually (rebase or force-push with-lease — both require their explicit approval).
- **`gh pr create` fails**: stop at Step 4. The branch is already pushed; the user can re-attempt manually.
- **PR already open for branch**: surfaced in preflight; user decides whether to refresh checks (no-op here, but build+test ran) or abort.

Begin by parsing arguments and running Step 0 now.
