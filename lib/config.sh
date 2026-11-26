# vim: filetype=bash

# This script reads the Dr Bash global configuration file: global.conf
# This file doesn't usually have to be sourced directly because it's sourced from other common include files.

[[ $__config ]] && return 0 
declare -g __config=1

# source "${DRB_LIB:-/usr/local/lib}/logging.sh"

declare -g DRBASH_VERSION="0.7"

GetDrBashVersion() {
  echo "Dr. Bash $DRBASH_VERSION ($(GetDrBashEdition))"
}

GetDrBashEdition() {
  if [[ -n "$DRB_EDITION" ]]; then
    printf "%b" "$DRB_EDITION"
  else
    [[ "$(GetDrBashModules)" ]] \
      && printf "%b" "Full" \
      || printf "%b" "Lite"
  fi
}

GetDrBashModules() {
  [[ -d "$DRB_SRC/media.shd" ]] && echo "media"
}

SourceConfigFile() {
  declare -g GLOBAL_CONFIG_FILE="$(ConfigGet_DATA)/global.conf"
  
  if [ -r "$GLOBAL_CONFIG_FILE" ]; then
    source "$GLOBAL_CONFIG_FILE"
  else
    LogError "FATAL: Configuration file does not exist or is not readable: $GLOBAL_CONFIG_FILE
Note: The location of the configuration file can be controlled via the DRB_DATA environment variable."
    exit 1
  fi
}

GlobalConfigFile() {
  printf "%s" "$GLOBAL_CONFIG_FILE"
}

# Default values
declare -r _DATA_DEF="$HOME/.DrBash"   # Must match DRB_DATA in install.sh
declare -r _SRC_DEF="/usr/local"
declare -r _LIB_DEF="$_SRC_DEF/lib"
declare -r _ENV_DEF="$_SRC_DEF/env"
declare -r _BIN_DEF="$_SRC_DEF/bin"

declare -r _LOG_COLOR_DEF=true
declare -r _LOG_TIMESTAMPS_DEF=true
declare -r _LOG_LABELS_DEF=true

VariableExists() {
  [[ -n "$1" ]] && declare -p "$1" >/dev/null 2>&1
}

_ValidateConfigValue() {
  local configName="$1"
  VariableExists "$configName" || return 1
  local -n configValue="$configName"
  
  # Note: The braces matter. "$configName_TYPE" would expand a variable named 'configName_TYPE'.
  local typeName="${configName}_TYPE"
  local configType="string"
  VariableExists "$typeName" && configType="${!typeName}"

  LogDebug "Validating config variable: $configName"

  case "$configType" in
    @*)                 # Custom Regex
      local _regex="${configType:1}"
      LogDebug "Validating config value $configValue using custom regex: $_regex"
      printf "%s" "$configValue" | grep -qE "$_regex" && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    bool)               # Boolean
      LogDebug "Validating config value $configValue as bool"
      printf "%s" "$configValue" | grep -qEi '^([01]|true|false|yes|no)$' && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    params)             # Set of function parameters
      LogDebug "Validating config value $configValue as params[]"
      printf "%s" "$configValue" | grep -qE '([[:alnum:] .-]+)' && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    abs_path)           # Absolute path
      LogDebug "Validating config value $configValue as absolute path"
      [[ "$configValue" == /* ]] && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    rel_path)           # Relative path
      LogDebug "Validating config value $configValue as relative path"
      [[ -n "$configValue" && "$configValue" != /* ]] && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    path)
      LogDebug "Validating config value $configValue as path"
      [[ -n "$configValue" ]] && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    "" | string)
      LogDebug "Validating config value $configValue as string"
      return 0 ;;
    *)
      LogError "Unrecognized config type: $configType. Failing validation."
      return 1 ;;
  esac
}

# [Internal] Returns the full path to the configuration file where the specified setting is defined.
# + $1 = The name of a configuration setting
# - stdout = The absolute path to the corresponding configuration file or "" if prohibited.
# - retVal = 0 if the configuration file could be determined
#            1 if you specified a valid config setting, but this function hasn't heard of it yet.
#            2 if you specified one of the top-level config settings (e.g. DRB_ENV)
#            3 if we don't know what in the hell you passed in, if anything at all!
# Note: You cannot change the non-scoped variables via this API (e.g. DRB_LIB). 
#   You could manually set them temporarily.
#   But any permanent change requires the user to update their startup files.
_GetConfigFile() {
  # This implementation might give you heartburn, so I'll attempt to explain how this works...
  # Problem? This function calls the function MediaConfigFile() which is not defined here or in any sourced file.
  # But How? In order for anyone to ask about a media-related config setting, they must have the media pack installed.
  #   Ergo, they will have sourced media-config.sh which actually sources this file.
  #   But the point is, it doesn't matter who sources whom, it all just gets lumped together in the environment.
  #   So as long as media-config.sh is sourced before this function is called, we're golden, dawg!
  local _var_name="$1"
  case "$_var_name" in
    DRB_DATA | DRB_SRC | DRB_LIB | DRB_ENV | DRB_BIN | DRB_EDITION | DRB_MEDIA_LIB)
      return 2 ;;
    DRB_LOG*)
      GlobalConfigFile ;;
    DRB_MEDIA*)
      MediaConfigFile ;;
    DRB_*.*)
      return 1 ;;
    *)
      return 3 ;;
  esac
}

# Interprets the value passed in as a boolean (case-insensitive).
# + $1 = The value to evaluate
# - retVal = 0 = true  (true, yes, 1)
#            1 = false (false, no, 0)
#            2 = unknown (anything else)
ConfigEvalBool() {
  case "${1,,}" in
    true | yes | 1) return 0 ;;
    false | no | 0) return 1 ;;
    *)              return 2 ;;
  esac
}

# Returns the value of the specified configuration setting or its default value, if not set
# + $1 = The name of the configuration setting
# - stdout = The requested value
# Note: You may omit the DRB_ variable name prefix or leave it intact. This function will work either way.
ConfigGet() {
  [[ -z "$1" ]] && return 1
  local _config_item_name="${1/DRB_/}"                    # Strip the DRB_ prefix, if present
  local -n _config_item="DRB_${_config_item_name}"        # Construct the name of the variable & dereference
  local -n _config_item_def="_${_config_item_name}_DEF"   # Construct the name of the default value & dereference
  printf "%s" "${_config_item:-$_config_item_def}"        # Print the value, if set. Otherwise, give 'em the default
}

# Sets the value of the specified configuration setting
# + $1 = (opt) Value persistence flag:
#           TEMP = Value should only persist for as long as the current script does
# + $2 = The name of the configuration setting
# + $3 = The new value of the configuration setting
# - retVal = 0 if the value was set (and saved, unless TEMP)
#            1 if the name or value is missing
#            2 if the configuration file can't be read or written
#            3 if the setting doesn't exist (this can't be used to invent new settings)
#            4 if the setting is read-only (e.g. DRB_LIB; set those in ~/.bashrc instead)
# Notes:
# 1. This method does not validate the value you're trying to set,
#       so be sure that you're setting a value that makes sense!
# 2. If you forget the DRB_ prefix, we got u dawg!
# 3. A known setting (one with a default value) that's missing from the file gets appended to it.
ConfigSet() {
  [[ -z "$2" ]] && return 1
  [[ "$1" == TEMP ]] && { local _temp=1; shift; }

  local _var_name="$1"
  local _var_value="$2"

  [[ "$_var_name" != DRB_* ]] && _var_name="DRB_${_var_name}"

  if [[ ! "$_temp" ]]; then
    # Find the file before touching the variable so a refused setting stays unchanged
    local _config_file
    _config_file="$(_GetConfigFile "$_var_name")"
    case $? in
      0) ;;
      2) return 4 ;;      # Top-level setting (e.g. DRB_LIB): read-only
      *) return 3 ;;      # Not a setting we know where to save
    esac
    [[ -r "$_config_file" && -w "$_config_file" ]] || return 2

    local _in_file=
    grep -q "^${_var_name}=" "$_config_file" && _in_file=1
    [[ "$_in_file" ]] || VariableExists "_${_var_name#DRB_}_DEF" || return 3
  fi

  local -n _var="$_var_name"
  local _old_value="$_var"
  _var="$_var_value"

  [[ "$_temp" ]] && return 0
  [[ "$_in_file" && "$_old_value" == "$_var_value" ]] && return 0

  # Edit the config file to make the setting change permanent.
  # %q quotes the value so that sourcing the file gives back exactly what was set (spaces and all).
  local _line
  printf -v _line '%s=%q' "$_var_name" "$_var_value"
  if [[ "$_in_file" ]]; then
    local _sed_line="${_line//\\/\\\\}"     # Escape what's special in a sed replacement: \ & |
    _sed_line="${_sed_line//&/\\&}"
    _sed_line="${_sed_line//|/\\|}"
    sed -i.bak "s|^${_var_name}=.*$|${_sed_line}|" "$_config_file" || return 2
  else
    printf '%s\n' "$_line" >> "$_config_file" || return 2
  fi
}

# User configuration files
ConfigGet_DATA() {
  printf "%s" "${DRB_DATA:-$_DATA_DEF}"
}

# The main Dr Bash installation directory
ConfigGet_SRC() {
  printf "%s" "${DRB_SRC:-$_SRC_DEF}"
}

# The Dr. Bash library directory (you shouldn't ever have to change this)
ConfigGet_LIB() {
  printf "%s" "${DRB_LIB:-$_LIB_DEF}"
}

# The Dr. Bash environment directory (you shouldn't ever have to change this)
ConfigGet_ENV() {
  printf "%s" "${DRB_ENV:-$_ENV_DEF}"
}

# The Dr. Bash binaries directory (you shouldn't ever have to change this)
ConfigGet_BIN() {
  printf "%s" "${DRB_BIN:-$_BIN_DEF}"
}

# Enable colored text in logs (future)
ConfigGetBool_LOG_COLOR() {
  ConfigEvalBool "${DRB_LOG_COLOR:-$_LOG_COLOR_DEF}"
  return $?
}

# Enable timestamped logs (future)
ConfigGetBool_LOG_TIMESTAMPS() {
  ConfigEvalBool "${DRB_LOG_TIMESTAMPS:-$_LOG_TIMESTAMPS_DEF}"
  return $?
}

# Enable printing of the log level in each log message. (future)
ConfigGetBool_LOG_LABELS() {
  ConfigEvalBool "${DRB_LOG_LABELS:-$_LOG_LABELS_DEF}"
  return $?
}

SourceConfigFile
