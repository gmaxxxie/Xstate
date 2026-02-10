---
name: publish-github-release
description: Use when asked to publish any git repository to GitHub with commit, push, tag, or release actions, including requests like "git commit/push", "publish a new version", "create GitHub release", or "ship this repo" across mixed language stacks.
---

# Publish GitHub Release

## Overview

Publish repeatable releases with a strict sequence: verify, commit, push, tag, release.

Core principle: collect fresh command evidence before every completion claim.

## Prerequisites

Run these checks first:

```bash
git rev-parse --is-inside-work-tree
git remote -v
gh --version
gh auth status
```

If `gh auth status` fails, stop and ask the user to re-authenticate before release commands.

## Select Verification Command

Pick one primary verification command before commit/push/release:

| Project signal | Verification command |
|---|---|
| `Package.swift` | `swift test` |
| `package.json` | `npm test` (or project-specific test script) |
| `pyproject.toml` / `requirements.txt` | `pytest` |
| `go.mod` | `go test ./...` |
| `Cargo.toml` | `cargo test` |

If the project has no obvious test command, ask for an explicit verification command and run it before publishing.

## Release Workflow

Execute in order:

1. Inspect current state.
```bash
git status --short --branch
git log --oneline --decorate -n 5
```
2. Run verification command and confirm exit code is `0`.
3. If working tree is dirty, stage and commit.
```bash
git add -A
git commit -m "<type>: <summary>"
```
4. Push current branch.
```bash
git push
```
5. Choose release tag (typically SemVer like `v1.2.3`) and check tag state.
```bash
git tag --list | rg "^v"
git ls-remote --tags origin
```
6. Create and push tag if missing.
```bash
git tag -a <tag> -m "release <tag>"
git push origin <tag>
```
7. Check whether release already exists.
```bash
gh release view <tag>
```
8. If release exists, update it; otherwise create it.
```bash
# create
gh release create <tag> --title "<tag>" --notes "<notes>"

# update existing release
gh release edit <tag> --title "<tag>" --notes "<notes>"
```
9. Report final state with:
   - commit SHA
   - branch sync status (`git status --branch`)
   - tag
   - release URL

## Quick Reference

| Task | Command |
|---|---|
| Check dirty tree | `git status --short` |
| Commit all tracked/untracked changes | `git add -A && git commit -m "<msg>"` |
| Push branch | `git push` |
| Create annotated tag | `git tag -a <tag> -m "release <tag>"` |
| Push one tag | `git push origin <tag>` |
| View release | `gh release view <tag>` |
| Create release | `gh release create <tag> --title "<tag>" --notes "<notes>"` |
| Update release | `gh release edit <tag> --title "<tag>" --notes "<notes>"` |

## Reusable Script

Use `scripts/publish_release.sh` for idempotent execution with safety checks.

Examples:

```bash
# Dry run to preview steps
bash scripts/publish_release.sh --tag v1.2.3 --verify-cmd "swift test" --dry-run

# Full publish with commit + release notes
bash scripts/publish_release.sh \
  --tag v1.2.3 \
  --verify-cmd "swift test" \
  --commit-message "chore: release v1.2.3" \
  --notes "Release v1.2.3"
```

## Common Mistakes

- Skipping verification before claiming release success.
- Creating release before pushing branch/tag.
- Ignoring existing release/tag and failing on duplicate creation.
- Proceeding when `gh auth status` is invalid.
- Reporting "done" without release URL evidence.
