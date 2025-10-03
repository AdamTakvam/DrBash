# The set of functions in this library are intended for general use in all types of scripts
# They represent generic, common functionality that most scripts require
# 

# Protect against being sourced multiple times
[ "$__general" ] && return 0
__general=1

source "${DRB_LIB:-/usr/local/lib}/config.sh"

# Determines whether the current user has sudo privileges
# - Returns:  0 Current user has sudo privileges
#             1 Current user does not have sudo privileges
HasSudo() {
  # If the user is in the 'sudo' or 'root' groups, then they can execute the 'sudo' command
  if [ "$(groups | grep -E '\ssudo\s|\sroot\s')" ]; then
    return 0 
  else
    return 1
  fi
}
export -f HasSudo

# Aliases to functions don't work  :-(
CanSudo() {
  HasSudo
}

# Determines whether the current user is root
# - stdout:   "yes" if user is root
# - Returns:  0 Current user is root
#             1 Current user is not root
IsRoot() {
  if [ "$(whoami)" == 'root' ]; then
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

# Checks whether the current script file is being sourced vs executed. 
# - retval : 0 if sourced, 1 otherwise
IsSourced() {
  for (( i = 1; i < ${#BASH_SOURCE[@]}; i++ )); do
    [[ "${BASH_SOURCE[$i]}" == "$0" ]] || return 0
  done
  return 1
}

# Determines whether this script is being invoked interactively by a user 
#   or via another script 
#   or in a piped command chain
# Only intended to be used by scripts that are not intended to be sourced.
# + $1     = The value of $0 in the executing context. Should be just: "$0"
# - stdout : Non-null is this script session is interactive. 
# - retval : 0 if interactive, 1 otherwise
IsInteractive() {
  if IsPiped || [[ -z "$PS1" ]]; then
    return 1
  else
    return 0
  fi
}

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
    return 99
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
