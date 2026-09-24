#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
source_app="$project_dir/dist/Mac Toolbox.app"
installed_app="${MAC_TOOLBOX_INSTALL_PATH:-/Applications/Mac Toolbox.app}"
installed_parent="${installed_app:h}"
staged_app="$installed_parent/.Mac Toolbox.app.new.$$"
backup_app="$installed_parent/.Mac Toolbox.app.backup.$$"

cleanup() {
    if [[ -d "$staged_app" ]]; then
        rm -rf "$staged_app"
    fi
}
trap cleanup EXIT

cd "$project_dir"

echo "Building Mac Toolbox..."
"$project_dir/scripts/package-app.sh" >/dev/null

echo "Staging the new app..."
mkdir -p "$installed_parent"
ditto "$source_app" "$staged_app"

echo "Stopping Mac Toolbox..."
pkill -x MacToolbox 2>/dev/null || true
for _ in {1..50}; do
    if ! pgrep -x MacToolbox >/dev/null; then
        break
    fi
    sleep 0.1
done

if pgrep -x MacToolbox >/dev/null; then
    echo "Mac Toolbox did not quit; leaving the installed app unchanged." >&2
    exit 1
fi

if [[ -e "$installed_app" ]]; then
    mv "$installed_app" "$backup_app"
fi

if ! mv "$staged_app" "$installed_app"; then
    if [[ -e "$backup_app" ]]; then
        mv "$backup_app" "$installed_app"
    fi
    echo "Installation failed; restored the previous app." >&2
    exit 1
fi

if [[ -e "$backup_app" ]]; then
    rm -rf "$backup_app"
fi

echo "Opening $installed_app"
open "$installed_app"
echo "Mac Toolbox is up to date."
