#!/bin/bash

set -euo pipefail

source "${DRB_LIB:-/usr/local/lib}/drbash.sh"

declare -r WWW_ROOT="${WWW_ROOT:-$HOME/public_html}"
declare -r USERTEMP="${USERTEMP:-~/temp}"
declare -r APPNAME='grav-listplugins'

# Create $USERTEMP if it doesn't already exist
[[ -d "$USERTEMP" ]] || mkdir -p "$USERTEMP"

InstallPlugin() {
  for pkg in "$@"; do
    plugin_zip="$USERTEMP/$pkg.zip"
    plugin_url="https://getgrav.org/download/plugins/$pkg/latest"
    
    echo "📦 Installing Grav plugin: $pkg"
    echo "📥 Downloading from: $plugin_url"
    
    umask 002
    
    [[ -f "$plugin_zip" ]] && mv -f "$plugin_zip" "$plugin_zip.bak"
  
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
}

if [ -z "${1:-}" ]; then
  Help
  exit 1
fi

InstallPlugin "$@"
