#!/bin/bash

set -euo pipefail

WWW_ROOT="${WWW_ROOT:-/var/www/html}"
TMPDIR="${TMPDIR:-/tmp}"

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <plugin-name>"
  exit 1
fi

for pkg in "$@"; do
  plugin_zip="$TMPDIR/$pkg.zip"
  plugin_url="https://getgrav.org/download/plugins/$pkg/latest"
  
  echo "📦 Installing Grav plugin: $pkg"
  echo "📥 Downloading from: $plugin_url"
  
  umask 002
  
  if ! wget -q "$plugin_url" -O "$plugin_zip"; then
    echo "❌ Failed to download plugin '$pkg'"
    exit 2
  fi
  
  if ! unzip -o "$plugin_zip" -d "$WWW_ROOT/user/plugins/" > /dev/null; then
    echo "❌ Failed to unzip plugin to '$WWW_ROOT/user/plugins/'"
    rm -f "$plugin_zip"
    exit 3
  fi
  
  rm -f "$plugin_zip"

  echo "✅ Plugin '$pkg' installed successfully."
done

echo "🧹 Clearing Grav cache..."
"$WWW_ROOT/bin/grav" clear-cache > /dev/null
