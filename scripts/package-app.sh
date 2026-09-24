#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/dist/Mac Toolbox.app"
contents_dir="$app_dir/Contents"

cd "$project_dir"
swift build -c release
rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp .build/release/MacToolbox "$contents_dir/MacOS/MacToolbox"
cp App/Info.plist "$contents_dir/Info.plist"
codesign --force --deep --sign - "$app_dir"
echo "$app_dir"
