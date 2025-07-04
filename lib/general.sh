# The set of functions in this library are intended for general use in all types of scripts
# They represent generic, common functionality that most scripts require
# 

# Protect against being sourced multiple times
[ "$__general" ] && return 0
__general=1

SourceConfigFile() {
  if [ -z "$MEDIADATA" ]; then
    declare -g MEDIADATA="${USERDATA:-$HOME/.mediadata}"
  fi

  if [ -z "$MEDIACONFIG" ]; then
    declare -g MEDIACONFIG="${MEDIADATA}/media-scripts.conf"
  fi

  if [ -r "$MEDIACONFIG" ]; then
    source "$MEDIACONFIG"
  else
    LogError "Warning: Configuration file does not exist or is not readable: $MEDIACONFIG"
    LogError "Notes:"
    LogError "1. The location of the configuration file can be controlled via the MEDIADATA environment variable."
    LogError "2. To suppress this warning, just create an empty file at that location.\n"
  fi
}

# Determines whether the current user has sudo privileges
# - stdout:   "yes" if user has sudo privileges
# - Returns:  0 Current user has sudo privileges
#             1 Current user does not have sudo privileges
HasSudo() {
  # If the user is in the 'sudo' or 'root' groups, then they can execute the 'sudo' command
  if [ "$(groups | grep -E '\ssudo\s|\sroot\s')" ]; then
    echo "sudo"
    return 0 
  else
    return 1
  fi
}
export -f HasSudo

alias CanSudo='HasSudo'

# Determines whether the current user is root
# - stdout:   "yes" if user is root
# - Returns:  0 Current user is root
#             1 Current user is not root
IsRoot() {
  if [ "$(whoami)" == 'root' ]; then
    echo "root"
    return 0 
  else
    return 1
  fi
}
export -f IsRoot

# Checks whether the current script instance is running within the context of a piped output chain. 
# - stdout : Non-null if session is piped
# - retval : 0 if piped, 1 otherwise
IsPiped() {
  if [ -t 1 ]; then 
    return 1
  else
    return 0
  fi
}

# Checks whether the current script instance is being sourced vs executed. 
# + $1     = The value of $0 in the executing context. Should be just: "$0"
# - stdout : Non-null if session is soourced
# - retval : 0 if sourced, 1 otherwise
IsSourced() {
  exeName="${1:-$0}"

  # The executable name may be anywhere in the array 
  #   depending on howe many levels of sourcing or function calls are happening
  for bs in "${BASH_SOURCE[@]}"; do
    [[ "$bs" == "$exeName" ]] && return 1
  done

  echo "sourced"
  return 0
}

# Determines whether this script is being invoked interactively by a user 
#   or via another script 
#   or in a piped command chain
# Only intended to be used by scripts that are not intended to be sourced.
# + $1     = The value of $0 in the executing context. Should be just: "$0"
# - stdout : Non-null is this script session is interactive. 
# - retval : 0 if interactive, 1 otherwise
IsInteractive() {
  if [ "$(IsPiped)" ] || [ "$(IsSourced "$1")" ]; then
    return 1
  else
    echo "interactive"
    return 0
  fi
}

# Ensures that the specified package is installed
# + $1 = Package name
# - Returns:  0   Package is installed
#             99  No package was specified
Require() {
  local pkg="$1"

  case "$pkg" in
    "")
      LogError "Require() Error: No package name specified!"
      return 99 ;;
    apt | dpkg | coreutils)
      LogError "Require() Warning: $pkg is always assumed to be installed."
      return 0 ;;
  esac

  if [ -z "$(apt list --installed 2>/dev/null | grep ^$pkg\/)" ]; then
    Log "Updating packages. Please wait..."
    sudo apt update 1>/dev/null
    if [ "$(apt list 2>/dev/null | grep ^$pkg\/)" ]; then
      Log "Installing required package: $pkg"
      sudo apt-get install -y "$pkg" 1>/dev/null
    else
      LogError "Require() Error: Package $pkg is not installed and does not exist in configured repositories."
      exit 1
    fi
  fi
}
export -f Require

alias Requires='Require'

# Returns the directory where the currently-executing script is located
# Note: This method only works if called from a shell script that has sourced this library.
#   Don't tell me about it not working when you call it direct from the shell. I don't want to hear it!
#
# + $1 = The value of ${BASH_SOURCE[0]} <-- Literally just pass this in!
# - stdout = The fully-qualified path of the directory containing the currently-executing script.
# - Returns 98  Resolved path does not exist (garbage in, garbage out)
# -         99  Parameter is null or ""
# - Otherwise, it returns 0 (success)
GetExecPath() {
  local -r FNAME="general.GetExecPath()" 

  # Get the path that was used to execute this script
  execPath="$1"
  LogDebugError "$FNAME: execPath = $execPath" 

  # If execPath is empty, then someone is calling this function in an unexpected way
  if [ -z "$execPath" ]; then
    LogError "$FNAME: Either you forgot to pass in \${BASH_SOURCE[0]} or \
      you attempted to call this method from a context other than from within a shell script."
    exit 99
  fi

  # Cleanse it of any symlinks and get right with Jesus
  execPath="$(realpath "$execPath")"
  LogDebugError "$FNAME: execPath = $execPath" 

  execPath="$(dirname -- "$execPath")"
  LogDebugError "$FNAME: execPath = $execPath" 

  [ -d "$execPath" ] && echo "$execPath" || return 98
}
export -f GetExecPath

# The following line is done to avoid one of many bash gotchas 
#   if you decide to use the 'cd' command in your script
unset CDPATH

source "${USERLIB:-$HOME/lib}/logging.sh"
SourceConfigFile
