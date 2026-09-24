#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"

branch="$(git branch --show-current)"
if [[ "$branch" != "main" ]]; then
    echo "Refusing to ship from '$branch'; switch to main first." >&2
    exit 1
fi

git push origin main
"$project_dir/scripts/update-installed-app.sh"
