#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  publish_release.sh --tag <tag> [options]

Required:
  --tag <tag>                    Release tag (example: v1.2.3)

Options:
  --verify-cmd "<cmd>"           Verification command to run before publish
  --commit-message "<msg>"       Commit message used when working tree is dirty
  --title "<title>"              Release title (default: tag)
  --notes "<text>"               Release notes text
  --notes-file <path>            Path to release notes file
  --remote <name>                Git remote (default: origin)
  --branch <name>                Branch to push (default: current branch)
  --dry-run                      Print commands without executing
  --help                         Show this help

Behavior:
  1) Verify repo/auth preconditions
  2) Run verification command (if provided)
  3) Commit if dirty and commit message is provided
  4) Push branch
  5) Create/push tag if needed
  6) Create or update GitHub release idempotently
EOF
}

TAG=""
VERIFY_CMD=""
COMMIT_MESSAGE=""
TITLE=""
NOTES_TEXT=""
NOTES_FILE=""
REMOTE="origin"
BRANCH=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="$2"
      shift 2
      ;;
    --verify-cmd)
      VERIFY_CMD="$2"
      shift 2
      ;;
    --commit-message)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --notes)
      NOTES_TEXT="$2"
      shift 2
      ;;
    --notes-file)
      NOTES_FILE="$2"
      shift 2
      ;;
    --remote)
      REMOTE="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$TAG" ]]; then
  echo "Missing required --tag argument." >&2
  usage >&2
  exit 2
fi

if [[ -n "$NOTES_TEXT" && -n "$NOTES_FILE" ]]; then
  echo "Use only one of --notes or --notes-file." >&2
  exit 2
fi

if [[ -z "$TITLE" ]]; then
  TITLE="$TAG"
fi

if [[ -z "$NOTES_TEXT" && -z "$NOTES_FILE" ]]; then
  NOTES_TEXT="Release $TAG"
fi

run() {
  echo "+ $*"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@"
  fi
}

run_shell() {
  echo "+ $*"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    bash -lc "$*"
  fi
}

if [[ -z "$BRANCH" ]]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Current directory is not a git repository." >&2
  exit 1
fi

command -v git >/dev/null 2>&1 || { echo "git not found." >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh not found." >&2; exit 1; }

run gh auth status

if [[ -n "$VERIFY_CMD" ]]; then
  run_shell "$VERIFY_CMD"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  if [[ -z "$COMMIT_MESSAGE" ]]; then
    echo "Working tree is dirty. Provide --commit-message to commit before release." >&2
    exit 1
  fi
  run git add -A
  run git commit -m "$COMMIT_MESSAGE"
fi

run git push "$REMOTE" "$BRANCH"

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1; then
  echo "Local tag $TAG already exists."
else
  run git tag -a "$TAG" -m "release $TAG"
fi

run git push "$REMOTE" "$TAG"

if gh release view "$TAG" >/dev/null 2>&1; then
  if [[ -n "$NOTES_FILE" ]]; then
    run gh release edit "$TAG" --title "$TITLE" --notes-file "$NOTES_FILE"
  else
    run gh release edit "$TAG" --title "$TITLE" --notes "$NOTES_TEXT"
  fi
else
  if [[ -n "$NOTES_FILE" ]]; then
    run gh release create "$TAG" --title "$TITLE" --notes-file "$NOTES_FILE"
  else
    run gh release create "$TAG" --title "$TITLE" --notes "$NOTES_TEXT"
  fi
fi

echo
echo "Release flow completed."
echo "  branch: $BRANCH"
echo "  tag:    $TAG"
echo "  remote: $REMOTE"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  mode:   dry-run"
fi
