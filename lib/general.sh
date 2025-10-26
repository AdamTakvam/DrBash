# The set of functions in this library are intended for general use in all types of scripts
# They represent generic, common functionality that most scripts require
# 

# Protect against being sourced multiple times
[[ ${__general-} == 1 ]] && return 0
declare -g __general=1

# Determines whether the current user has sudo privileges
# - Returns:  0 Current user has sudo privileges
#             1 Current user does not have sudo privileges
HasSudo() {
  # If the user is in the 'sudo' or 'root' groups, then they can execute the 'sudo' command
  [[ "$(groups | grep -E '\ssudo\s|\sroot\s')" ]] && return 0 || return 1
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
  if [[ $(whoami) == root ]]; then
    return 0 
  else
    return 1
  fi
}
export -f IsRoot

# Checks whether the output of the current script is redirected to some other destination than the display.
# Returns the same exact result as IsPiped, so there's no need to vall both.
# - retval : 0 if redirected, 1 otherwise
IsRedirected() {
  IsPiped
  return $?
}

# Checks whether the current script instance is running within the context of a piped output chain. 
# - retval : 0 if piped, 1 otherwise
IsPiped() {
  # This is a special test to see if stdout is connected to a terminal or being piped into another command.
  [[ -t 1 ]] && return 1 || return 0
}

# Checks whether the calling script file is being sourced vs executed. 
# - retval : 0 if sourced, 1 otherwise
IsSourced() {
  # Iterate through the call stack.
  # If we're not sourced, the only things that should be in there are this file 
  #   and the script that kicked off this madness.
  # Yes, I'm well aware of your [[ ${BASH_SOURCE[0]} != $0 ]] trick and it doesn't work here.
  #   I'll leave to you to figure out why. For bonus points, why did I initialize i to 1 and not 0?
  local i
  for (( i = 1; i < ${#BASH_SOURCE[@]}; i++ )); do
    # If the callstack entry is not equal to the name of the executing script...
    [[ "${BASH_SOURCE[$i]}" == "$0" ]] && continue
    # and it's not equal to the name of this script...
    [[ "${BASH_SOURCE[$i]}" == "${BASH_SOURCE[0]}" ]] && continue
    # then we been invoked in that funny left-handed sort of way!
    return 0
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
  # First, we check to see if the output of the current script is being directed at anything other than a terminal.
  # Then, we check to see if a typical login style environment exists in order to ensure proper operation
  # with services, cron jobs, and background processes.
  IsPiped || [[ -z "$PS1" ]] && return 1 || return 0
}

# Returns the directory where the currently-executing script is located
# Note: This method only works if called from a shell script that has sourced this library.
#   Don't tell me about it not working when you call it direct from the shell. I don't want to hear it!
#
# - stdout = The fully-qualified path of the directory containing the currently-executing script.
# - Returns 98  Resolved path does not exist (garbage in, garbage out)
# -         99  Parameter is null or ""
# - Otherwise, it returns 0 (success)
GetExecPath() {
  # Get the path that was used to execute this script
  local execPath="${BASH_SOURCE[-1]}"
  LogDebugError "execPath(1) = $execPath" 

  # Cleanse it of any symlinks and get right with Jesus
  execPath="$(realpath "$execPath")"
  LogDebugError "execPath(2) = $execPath" 

  execPath="$(dirname -- "$execPath")"
  LogDebugError "execPath(3) = $execPath" 

  [ -d "$execPath" ] && printf '%s' "$execPath" || return 98
}
export -f GetExecPath

# The following line is done to avoid one of many bash gotchas 
#   if you decide to use the 'cd' command in your script
unset CDPATH

# This is the function you were supposed to be calling instead of just 
#   puking commands into a file and hoping for the best.
# Now the document generator is crashing and you can't get unit testing to work
# Yup...
# That'll do that.
# Now wrap all of that crazy garbage you wrote in: Main() { <your crazy garbage goes here> }
# Then make sure that the very last line of your script is: RunMain
# Then you can proudly enter the modern era of script automation
RunMain() {
  if ! IsSourced; then
    Main "$@"
  fi
}

# The only correct way to implement primary script logic using the Dr. Bash framework 
#   is to implement a Main() function in your script and call 'RunMain "$@"' at the very end.
# There should be no loose code in a Dr. Bash script.
# Sure, you can still get away with defining global variables,
#   but you shouldn't. It's not best practice and it makes your life harder, not easier!
# Yes, I'm aware that I defined a global variable just 2 lines above this text block.
# I'm writing a library that's designed to make certain things global.
# You're not. You're writing a script that's using these libraries,
#   so stop being a smart-ass and just follow directions!
if ! IsSourced; then
  source "${DRB_LIB}/logging.sh"
  _LogMain "$@"
fi
