# The set of functions in this library are intended for general use in all types of scripts
# They represent generic, common functionality that most scripts require
# 
# To include in your script, copy/paste:
# source ${USERLIB:-$HOME/lib}/general.sh
#
# If you have chosen to locate this file elsewhere, then be sure to initialize the USERLIB variable in your .bashrc file. 
# Scripts call sudo as necessary, so you should never have to use sudo to call any library function.
#
# Return values:
#   0     Successfully accomplished whatever it was intended to accomplish
#   1-9   General error (catch-all category for an error that doesn't fit any of the other categories)
#   10-19 The user interrupted execution in some way
#   20-29 The operation aborted because the intended result has already been achieved or is logically unnecessary
#   30-39 A dependency could not be resolved or some other necessary resource could not be located
#   90-99 The programmer didn't program correctly
#
# Implementation notes for scripts sourcing this library:
#   - This is not just a library; it's a scripting paradigm
#   - Use the provided script.template file for any new scripts that you write
#   - Your script WILL be sourced 
#       so have all of your logic in functions 
#       and protect the main method call as provided in the template script
#   - User the various Log() functions (in logging.sh) for your script's output
#       echo should only be used for help screens, 
#       returning values from functions,
#       and piping string values into other functions or commands

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
    echo "yes"
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
  if [ "$(whoami)" == "root" ]; then
    echo "yes"
    return 0 
  else
    return 1
  fi
}
export -f IsRoot

# Checks whether the current script instance is running within the context of a live, interactive user session 
#   or via some automated process like cron or systemd or whatever.
# - stdout : Some text if session is interactive, otherwise nothing
# - retval : 0 if interactive, 1 otherwise
IsInteractive() {
  if [ -t 1 ] ; then 
    echo "interactive"
    return 0
  else
    return 1
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
