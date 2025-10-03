#!/bin/bash

set -euo pipefail

source "${DRB_LIB:-/usr/local/lib}/drbash.sh"

declare -r WWW_ROOT="${WWW_ROOT:-$HOME/public_html}"
declare -r USERTEMP="${USERTEMP:-~/temp}"
declare -r APPNAME='grav-listplugins'

# Create $USERTEMP if it doesn't already exist
[[ -d "$USERTEMP" ]] || mkdir -p "$USERTEMP"

Help() {
  Log "Lists all of the currently available plugins for Grav CMS."
  Log
  Log "$(Header "Usage:") $APPNAME [OPTIONS] [PLUGIN]"
  Log
  LogHeader "OPTIONS:"
  LogTable "\t-u\tDisplay download URL.
  \t-d\tDisplay description.
  \t-c\tClear the plugin metadata cache.
  $(LogParamsHelp)"
  Log
  Log "$(Header "PLUGIN:")\tThe name of a plugin to get metadata for."
  Log
  Log "If no options are specified, $APPNAME will display the names of all available plugins."
  Log "$APPNAME also marks plugins that are premium $(ColorText LGREEN '($$$)') and those that are installed $(ColoreText LBLUE '(i)')"
}

declare -i disp_url=0
declare -i disp_desc=0
declare -i clr_cache=0
declare query

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      -u)
        disp_url=1 ;;
      -d)
        disp_desc=1 ;;
      -c)
        clr_cache=1 ;;
      -*)
        ;;
      *)
        query="$p" ;;
    esac
  done
}

IsPluginPremium() {
  url="$1"
  if [[ "$(echo "$url" | grep '://gum.co/')" ]]; then
    Log "$(ColorText LGREEN '$$$')"
    return 0
  else
    return 1
  fi
}

declare inst_plugins

# + $1 = The plugin name
IsPluginInstalled() {
  local _pName="$1"
  [ "$pName" ] || return 99

  if [ -z "$inst_plugins" ]; then
    inst_plugins="$(find "$WWW_ROOT/user/plugins/" -maxdepth 1 -type d | sed -E 's:plugins/(.*)$:\1:' | paste -sd,)"
  fi
  
  if [ "$(echo "$inst_pluginds" | grep "$pNanme")" ]; then
    Log "$(ColorText LBLUE "(i)")"
    return 0
  else
    return 1
  fi
}

GetPluginData() {
  local -r plugin_data="$USERTEMP/plugin.data"
  [[ -r "$plugin_data" ]] && mv -f "$plugin_data" "$plugin_data.bak"

  # Yes, the download URL is /download and this one is /downloads
  # It's a classic Grav move!
  if ! wget -q "https://getgrav.org/downloads/plugins" -O "$plugin_data"; then
    if [[ -r "$plugin_data.bak" ]]; then
      LogError "Warning: Failed to download plugins list. Using cached copy..."
      mv -f "$plugin_data.bak" "$plugin_data"
    else
      LogError "❌ Failed to download plugin list."
      return 2
    fi
  fi

  local -r inst_plugins="$(find "$WWW_ROOT/user/plugins/" -maxdepth 1 -type d | sed -En 's:plugins/(.*)$:\1:p' | paste -sd,)"

  IFS='~' plugins=($(grep -A17 --group-separator=~ 'card__title' "$plugin_data"))
  for data in $plugins; do
    IFS=$'\n' lines=($data)
    name="$(echo "${lines[1]}" | sed -E 's:.*>(.*)</a>.*:\1:')"
    url="$(echo "${lines[7]}" | sed -E 's:.*href="(.*)" target.*:\1:')"
    desc="$(echo "${lines[14]}" | sed -E 's:.*<p>(.*)</p>:\1:')"

    # Is this plugin nonsense?
    [[ "$name" == '/' ]] && continue

    # Is plugin already installed
    name+=" $(IsPluginInstalled "$name")"

    # Is this plugin premium?
    premBadge="$(IsPluginPremium "$url")"
    if [ "$premBadge" ] && [ $exclPrem -eq 1 ]; then
      continue
    else
      name+=" $premBadge"
    fi

  done
}

# + $1 = Display URL [0|1]
# + $2 = Display description [0|1]
ListPlugins() {

}

# + $1 = The plugin name
ShowPlugin() {
  local pName="$1"
  printf '%s\n' "$name" > "$USERTEMP/$name.data"
  [ "$disp_url" == 1 ] && printf "%s\n" "$url" > "$USERTEMP/$name.data"
  [ "$disp_desc" == 1 ] && printf "%s\n" "$url" > "$USERTEMP/$name.data"
  $desc" > "$USERTEMP/$name.data" 
}

if [ -z "${1:-}" ]; then
  Help
  exit 1
fi

ParseCLI "$@"

if [ "$query" ]; then
  ShowPlugin "$query"
else
  ListPlugins
