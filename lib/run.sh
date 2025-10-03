# Protect against being sourced multiple times
[ "$__run" ] && return 0
__run=1

source "${DRB_LIB:-/usr/local/lib}/general.sh"

# Executes the specified command(s) as root if not in debug mode
# + $1 = Optional flags
#         -u  User mode (default)
#         -r  Run as root (will fail if you don't have the perms! lol)
# + $2 = Command to execute
# + stdin = Command to execute + parameters
# + $VERBOSE = Log the exact command to be executed
# + $DEBUG = Inhibit running any environment-changing commands
# - stderr = The cammand to be executed (if $DEBUG or $VERBOSE)
# - Returns:  #   Exit code of command
#             98  Command could not be found
#             99  No command was specified
Run() {
  local -r FNAME="Run()"
  local cmdName

  # Process and mask any parameters intended for this function
  for p in "$@"; do
    case "$p" in
      -u)
        user=1
        shift ;;
      -r)
        CanSudo && root=1 \
                || LogVerboseError "$FNAME Warning: Root-level execution requested by program, but user doesn't have sudo permissions. Attempting to execute command as user: $(whoami)..." 
        shift ;;
      *)
        break ;;
    esac
  done
  
  # Automatic permission elevation mode
  if [ "$user" != 1 ] && [ "$root" != 1 ]; then 
    HasSudo && root=1 || user=1
  fi

  if [ "$root" == 1 ]; then
    LogVerbose "$(ColorText LRED "Executing command with elevated privileges")"
  else
    LogVerbose "Executing command with user privileges"
  fi

  # Assume that everything left is the command to be run
  local -ra ARGV=("$@")
  local cmdName="${ARGV[0]}"
  LogDebugError "$FNAME: cmdName = $cmdName"

  local cmd
  if [ -z "$cmdName" ]; then
    cmd="$(read cmd; echo "$cmd")"
  else
    cmd="$(_Run_FindCmd "$cmdName") "
    if [ "$?" != 0 ]; then
      LogError "$FNAME Error: Command not found: $cmdName"
      return 98
    fi

    # Ensure proper parameter quoting is maintained
    for (( index=1; $index < ${#ARGV[@]}; index++ )); do
      local arg="${ARGV[$index]}"
      if [[ "$arg" =~ ^- ]]; then
        cmd+="$arg "
      else
        cmd+="\"$arg\" "
      fi
    done
  fi

  # Run the indicated command depending on the logging mode:
  # None = Run the command
  # Run the indicated command depending on the logging mode:
  # None = Run the command
  # Verbose = Print and run the command
  # Debug = Print the command, but do not run it
  #
  # Note: Output printed to stderr so that it can be 
  #   redirected/suppressed independently of any command output. 
  if [ "$cmd" ]; then
    cmd="${root:+sudo -E }$cmd"
    LogVerboseError "> $cmd"
    if [ -z "$DEBUG" ]; then
      [ $QUIET ] \
        && bash -c "$cmd" >/dev/null \
        || bash -c "$cmd"
      return $?
    else
      LogDebugError "$FNAME: Not executing $cmdName command because DEBUG mode is activated."
      return 0
    fi
  else
    return 99
  fi
}

# Ensures that the specified package is installed
# + $@ = Package names
# - Returns:  lol: If this function returns anything, everything is fine
#            rofl: If things aren't fine, your script dies. How's that for a return code?
# - Exit Codes  1: Package failed to install
#               2: Package does not exist in configured repos
Require() {
  [[ -z "$1" ]] && { LogError "No package name specified!"; return 99; }
  [[ -z "$(which apt)" ]] && { LogError "apt is not installed!"; return 98; }

  local -i retVal=1

  for pkg in "$@"; do
    if [ -z "$(apt list --installed 2>/dev/null | grep ^$pkg\/)" ]; then
      Log "Updating packages. Please wait..."
      sudo apt update 1>/dev/null
      if [ "$(apt list 2>/dev/null | grep ^$pkg\/)" ]; then
        Log "Installing required package: $pkg"
        sudo apt-get install -y "$pkg" 1>/dev/null || exit 1
      else
        LogError "Package $pkg is not installed and does not exist in configured repositories."
        exit 2
      fi
    fi
  done
}
export -f Require

Requires() {
  Require "$@"
}

# Determines whether the Run() command will succeed if/when it is called.
# Use this at the top of scripts to sanity check that Dr. Bash is installed correctly.
# For any non-Dr. Bash packaged dependencies, use Require().
#
# Note: This function will return success if a command passed in is an alias
#   but it does not check whether the target of the alias is valid
# If this function fails, here are some solutions:
#   1. Fully-qualify the command (e.g. /full/path/to/command)
#   2. Add the location of the desired command to the $PATH variable
#   3. Set $DRB_BIN to the path of the command
#
# + $@ The commands you want to run
# - Returns:  0 Commands will run
#             1 One or more of the specified commands will not run
CanRun() {
  _Run_FindCmd "$1" >/dev/null
}

# Internal: Locates the specified executable file
# + $1 = Executable file name
# - stdout = The resolved form of the specified executable file
# - Returns:  0   Successfully resolved executable
#             1   Specified executable could not be located
#             99  No file name was passed in
_Run_FindCmd() {
  local -r FNAME="_Run_FindCmd()"

  [ -z "$1" ] && return 99
#  LogDebugError "$FNAME: \$1 = $1"
  
  local cmdDir="$(dirname "$1")"
  # Fix for bug in dirname that returns . when no path exists
  cmdDir="$([ "$cmdDir" == '.' ] && echo "" || echo "$cmdDir/")"
  LogDebugError "$FNAME: cmdDir = $cmdDir"

  local cmdName="$(basename "$1")"
  LogDebugError "$FNAME: cmdName = $cmdName"
  
  # Strip off any parameters that may be along for the ride
  local -a cmdNameBits=($cmdName)
  local cmd="${cmdDir}${cmdNameBits[0]}"
  LogDebugError "$FNAME: cmd = $cmd"

  # Does $cmd contain a path to an executable file?
  # If $cmd contains a path and it isn't found
  #   then all other checks will also fail
  #   so don't bother
  if [ "$cmdDir" ]; then 
    if [ -x "$cmd" ]; then 
      LogDebugError "$FNAME: retVal = $cmd"
      echo "$cmd"
      return 0
    else
      LogVerboseError "$FNAME Error: The fully-qualified executable $cmd does not exist!"
      return 1
    fi
  fi

  # Is $cmd an alias, reserved word, function, builtin, or file in $PATH?
  local cmdType=$(type -t "$cmd")
  if [ "${cmdType,,}" == "file" ]; then
    LogDebugError "$FNAME: $cmd is a file in the PATH."
    echo "$cmd"
    return 0
  elif [ "$cmdType" ]; then
    LogDebugError "$FNAME: $cmd is a $cmdType."
    echo "$cmd"
    return 0
  fi

  # Is $cmd in the current directory?
  if [ -x "./$cmd" ]; then
    LogDebugError "$FNAME: $cmd is a file in the current working directory."
    echo "./$cmd"
    return 0
  fi

  # Is $cmd in the DRB_BIN directory?
  if [ -x "$DRB_BIN/$cmd" ]; then 
    LogDebugError "$FNAME: $cmd is a file in $DRB_BIN."
    echo "$DRB_BIN/$cmd"
    return 0
  fi
  
  # What about DRB_SRC? (remember it has subdirectories)
  local match="$(find "$DRB_SRC/" -executable -type f -name "$cmd" | head -1)" 
  if [ -x "$match" ]; then
    LogVerboseError "$FNAME: The best last-ditch effort to find $cmd is $match. I hope we're right..."
    echo "$match"
    return 0
  fi

  # What about DRB_LIB?  <-- Nothing in DRB_LIB should be executable, but whatevs...
  [ -x "$DRB_LIB/$cmd" ] && { echo "$DRB_LIB/$cmd"; return 0; }
  [ -x "$DRB_LIB/$cmd.sh" ] && { echo "$DRB_LIB/$cmd.sh"; return 0; }

  # Then we have no fucking idea how to run $cmd
  LogVerboseError "$FNAME Error: All efforts to locate the executable $cmd have failed!"
  return 1
}
