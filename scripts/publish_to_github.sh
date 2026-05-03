#!/usr/bin/env bash
# Create github.com/<you>/mlflow-projects (if missing), ensure remote "github", push branches.
# Prerequisite: run `gh auth login` once on this machine.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! gh auth status &>/dev/null; then
  echo "GitHub CLI is not logged in. Run: gh auth login"
  exit 1
fi

REMOTE_NAME="github"
LOGIN="$(gh api user -q .login)"
URL="https://github.com/${LOGIN}/mlflow-projects.git"

if git remote get-url "$REMOTE_NAME" &>/dev/null; then
  echo "Remote '$REMOTE_NAME' already configured."
elif gh repo view "${LOGIN}/mlflow-projects" &>/dev/null; then
  git remote add "$REMOTE_NAME" "$URL"
else
  gh repo create mlflow-projects \
    --public \
    --description "MLflow experiments, tracking, and automation" \
    --source=. \
    --remote="$REMOTE_NAME" \
    --push
fi

git push -u "$REMOTE_NAME" main
git push -u "$REMOTE_NAME" "feature/dev/project-learning"
git push -u "$REMOTE_NAME" "feature/prod/project-learning"

echo "Done. Remote: $(git remote get-url "$REMOTE_NAME")"
