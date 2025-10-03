# This script reads the Dr Bash global configuration file: global.conf
# This file doesn't usually have to be sourced directly because it's sourced from other common include files.

[[ $__config ]] && return 0 
declare -r __config=1

source "${DRB_LIB:-/usr/local/lib}/logging.sh"

declare -rg DRBASH_VERSION="0.7"

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
declare -r _DATA_DEF="$HOME/.drbash"
declare -r _SRC_DEF="/usr/local"
declare -r _LIB_DEF="$_SRC_DEF/lib"
declare -r _ENV_DEF="$_SRC_DEF/env"
declare -r _BIN_DEF="$_SRC_DEF/bin"

declare -r _LOG_COLOR_DEF=true
declare -r _LOG_TIMESTAMPS_DEF=true
declare -r _LOG_LABELS_DEF=true

VariableExists() {
  if declare -p "$1" >/dev/null; then
    return 0
  else
    return 1
  fi
}

_ValidateConfigValue() {
  local configName="$1"
  VariableExists "$configName" || return 1
  local -n configValue="$configName"
  
  if VariableExists "$configName_TYPE"; then
    local -n configType="$configName_TYPE"
  else
    local configType="string"
  fi

  LogDebug "Validating config variable: $configName"

  case "$configType" in
    @*)                 # Custom Regex
      local _regex="${configType:1}"
      LogDebug "Validating config value $configValue using custom regex: $_regex"
      printf "%s" "$configValue" | grep -E "$_regex" && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    bool)               # Boolean
      LogDebug "Validating config value $configValue as bool"
      printf "%s" "$configValue" | grep -Ei '([01]|true|false|yes|no)' && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    params)             # Set of function parameters
      LogDebug "Validating config value $configValue as params[]"
      printf "%s" "$configValue" | grep -E '([[:alnum:] .-]+)' && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    abs_path)           # Absolute path
      LogDebug "Validating config value $configValue as absolute path"
      printf "%s" "$configValue" | grep -E '([01]|true|false|yes|no)' && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    rel_path)           # Relative path
      LogDebug "Validating config value $configValue as relative path"
      printf "%s" "$configValue" | grep -E '([01]|true|false|yes|no)' && return 0 
      LogError "Validation of config variable $configName failed!"
      return 1 ;;
    path)
      LogDebug "Validating config value $configValue as path"
      printf "%s" "$configValue" | grep -E '([01]|true|false|yes|no)' && return 0 
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
    DRB_LOG*)
      GlobalConfigFile ;;
    DRB_MEDIA*)
      MediaConfigFile ;;
    DRB_*.*)
      return 1 ;;
    DRB_*)
      return 2 ;;
    *)
      return 3 ;;
  esac
}

# Outputs the appropriate return code based on a boolean interpretation of the value passed in.
# + $1 = The value to evaluate
# - stdout = The return code corredsponding to the value entered
#     0 = true
#     1 = false
#     -1 = unknown
ConfigEvalBool() {
  case "$1" in 
    true | yes | 1) printf 0 ;;
    false | no | 0) printf 1 ;;
    *)              printf -1 ;;
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
# - retVal = Success or failure to persist the new configuration value
# Notes: 
# 1. This method does not validate the value you're trying to set, 
#       so be sure that you're setting a value that makes sense!
# 2. If you forget the DRB_ prefix, we got u dawg!
ConfigSet() {
  [[ -z "$2" ]] && return 1
  [[ "$1" == TEMP ]] && { local _temp=1; shift; }

  local _var_name="$1"
  local _var_value="$2"

  [[ "$_var_name" != DRB_* ]] && _var_name="DRB_${_var_name}" 

  local -n _var="$_var_name"
  local _old_value="$_var"
  _var="$_var_value"

  if [[ ! "$_temp" ]] && [[ "$_old_value" != "$_var_value" ]]; then
    # Edit the config file to make the setting change permanent
    local _config_file="$(_GetConfigFile "$_var_name")"
    [[ "$?" == 0 ]] || return $?
    sed -Ei.bak "s|^$_var_name=.*$|$_var_name=$_var_value/" "${_config_file}"
  fi
  
  return $?
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
