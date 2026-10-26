#!/bin/bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: bash scripts/create-update-feed.sh /path/to/Sparkle v1.0.0 /path/to/archives" >&2
    exit 1
fi

sparkle_directory=$1
release_tag=$2
archives_directory=$3
keychain_account=cz.matee.fluidtime.sparkle
project_directory=$(cd "$(dirname "$0")/.." && pwd)

if [[ ! "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected a release tag such as v1.0.0" >&2
    exit 1
fi
if [[ ! -x "$sparkle_directory/bin/generate_appcast" || ! -x "$sparkle_directory/bin/generate_keys" ]]; then
    echo "Expected an official Sparkle distribution with signing tools" >&2
    exit 1
fi
if [[ ! -d "$archives_directory" ]]; then
    echo "The archive directory does not exist" >&2
    exit 1
fi

public_key=$("$sparkle_directory/bin/generate_keys" --account "$keychain_account" -p)
expected_key=$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$project_directory/Configuration/Info.plist")
if [[ "$public_key" != "$expected_key" ]]; then
    echo "The signing key does not match the app's public update key" >&2
    exit 1
fi

"$sparkle_directory/bin/generate_appcast" --account "$keychain_account" \
    --download-url-prefix "https://github.com/MateeDevs/fluidtime/releases/download/$release_tag/" \
    --maximum-deltas 0 "$archives_directory"
echo "Upload the signed archives, checksums, and appcast.xml only when a release is authorized."
