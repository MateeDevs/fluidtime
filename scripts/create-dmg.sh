#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: bash scripts/create-dmg.sh /path/to/Fluidtime.app /path/to/output-directory" >&2
    exit 1
fi

app_path=$1
output_directory=$2
info_plist="$app_path/Contents/Info.plist"
executable="$app_path/Contents/MacOS/Fluidtime"

if [[ ! -f "$info_plist" || ! -x "$executable" ]]; then
    echo "Expected a built Fluidtime.app bundle" >&2
    exit 1
fi

bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info_plist")
if [[ "$bundle_identifier" != "cz.matee.fluidtime" ]]; then
    echo "The app bundle is not Fluidtime" >&2
    exit 1
fi

/usr/bin/codesign --verify --deep --strict "$app_path"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist")
case "$version" in
    ''|*[!0-9A-Za-z._-]*) echo "Unsupported app version" >&2; exit 1 ;;
esac

architectures=$(/usr/bin/lipo -archs "$executable")
case "$architectures" in
    arm64) architecture=arm64 ;;
    x86_64) architecture=x86_64 ;;
    "arm64 x86_64"|"x86_64 arm64") architecture=universal ;;
    *) echo "Unsupported app architectures: $architectures" >&2; exit 1 ;;
esac

mkdir -p "$output_directory"
output_directory=$(cd "$output_directory" && pwd)
filename="Fluidtime-$version-$architecture.dmg"
image_path="$output_directory/$filename"
if [[ -e "$image_path" || -e "$image_path.sha256" ]]; then
    echo "An installer or checksum already exists at $image_path" >&2
    exit 1
fi

staging_directory=$(mktemp -d "${TMPDIR:-/tmp}/fluidtime-dmg.XXXXXX")
trap 'rm -rf "$staging_directory"' EXIT
/usr/bin/ditto "$app_path" "$staging_directory/Fluidtime.app"
/bin/ln -s /Applications "$staging_directory/Applications"
/usr/bin/codesign --verify --deep --strict "$staging_directory/Fluidtime.app"
/usr/bin/hdiutil create -volname Fluidtime -fs HFS+ -srcfolder "$staging_directory" \
    -format UDZO -imagekey zlib-level=9 "$image_path"
/usr/bin/hdiutil verify "$image_path"
(
    cd "$output_directory"
    /usr/bin/shasum -a 256 "$filename" > "$filename.sha256"
)
echo "Created $image_path"
echo "Created $image_path.sha256"
