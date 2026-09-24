#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"

git config core.hooksPath .githooks
git config alias.ship '!scripts/push-main-and-update.sh'

echo "Installed repository-local automation:"
echo "  git ship  - push main, then rebuild and reinstall"
echo "  git pull  - rebuild and reinstall after a merge into main"
