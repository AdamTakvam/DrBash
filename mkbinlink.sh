#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
declare -r SCRIPT_NAME="mkbinlink"

PrintHelp()
{
  tabs 4
  Log "Creates a softlink in the user bin directory to the specified user script file."
  Log
  Log "Usage: $SCRIPT_NAME [FLAGS] [FILE]"
  Log
  Log "FLAGS\t(optional) Operational flags."
  Log "\t-h\t\tDisplay this help text."
  Log "\t-i\t\tInteractive mode. Prompt before each link is created."
  Log "\t-q\t\tQuiet mode. Suppress output and assume the default response for any prompts. Overrides -v and -vv."
  Log "\t\t\t\tNote: Output to stderr and log files is not suppressed."
  Log "\t-v\t\tEnable verbose logging. -q disables this parameter."
  Log "\t-vv\t\tEnable more verbose logging (simulation-only mode). -q disables this parameter."
  Log
  Log "FILE\t(optional) The name of the script file to link. (default: ./*.sh)."
  Log "\t\t\tFile names containing a version in the form <name>-<Maj>.<min>.sh (e.g. myscript-1.0.sh) are ignored."
  Log "\t\t\tLink files named <name>-latest will be linked as <name>-dev"
  Log "\t\t\tLink files named <name>-stable will be linked as <name>"
  Log
  Log "Environment Variables:"
  Log "\tUSERSRC\tUser scripts directory (default: ~/src)"
  Log "\tUSERBIN\tUser binaries directory (default: ~/bin)"
  Log
}

# Parse command line args
while  [[ "$1" =~ ^-   ]]; do
  if   [[ "$1" =~ ^-h  ]]; then PrintHelp; exit 1 
  elif [[ "$1" =~ ^-i  ]]; then interactive=1; shift
  elif [[ "$1" =~ ^-vv ]]; then LogEnableDebug; shift
  elif [[ "$1" =~ ^-v  ]]; then LogEnableVerbose; shift
  elif [[ "$1" =~ ^-q  ]]; then LogEnableQuiet; shift
  else LogError "ERROR: Option not recognized: $1"; exit 1
  fi
done

declare -r srcDir="$(realpath "${USERSRC:-$HOME/src}")"
declare -r binDir="${USERBIN:-$HOME/bin}"

LogDebug "srcDir=$srcDir"
LogDebug "binDir=$binDir"

# Create binDir if it does not exist
[ ! -e $binDir ] && mkdir -p "$binDir"

# Create symlink in binDir to a library script
# + $1 = script file name [mandatory]
# + $srcDir = User scripts directory
# + $binDir = User binary directory
# - Return Values:
# 0 = Link created successfully.
# 1 = No parameter supplied in function call.
# 2 = Specified script file does not exist.
# 3 = Link already exists.
# Other? = See return codes for ln command.
LinkScript()
{
  declare -r FILE_EXT="sh"

  [ -z "$1" ] && { LogError "Script error: Missing parameter calling LinkScript()"; return 1; }

  # Create a softlink to the executable in the real lib path (if ~/lib is
  # a softlink) in the ~/bin directory with the same name except without the
  # '.sh' extension.
  local libFileName="$(basename "$1")"
  LogDebug "libFileName = $libFileName"
  
  local libFileDir="$(dirname "$1")"
  LogDebug "libFileDir = $libFileDir"

  # Remove file extension
  local linkFileName="${libFileName%.$FILE_EXT}"
  LogDebug "linkFileName = $linkFileName"
  
  # Don't create links to versioned files
  # These files will have softlinks referring to their stable and dev versions
  local vlibFileName="$(echo "$libFileName" | grep "\-[0-9]\.[0-9].sh$")"
  if [ "$vlibFileName" ]; then
    LogError "Ignoring versioned script: $libFileName"
    unset vlibFileName 
    return 20
  fi
  
  # Don't make links to backup files
  local blibFileName="$(echo "$libFileName" | grep -E ".bak$|~$")"
  if [ "$blibFileName" ]; then
    LogError "Ignoring backup script: $libFileName"
    unset blibFileName 
    return 21
  fi

  # Make a few substitutions for reserved words/symbols in names 
  linkFileName="$(echo "$linkFileName" | sed 's/latest$/dev/')"
  linkFileName="$(echo "$linkFileName" | sed 's/\-stable$//')"
  linkFileName="$(echo "$linkFileName" | sed 's/^_//')"

  # Reassemble fully-qualified paths
  local libFile="$libFileDir/$libFileName"
  LogDebug "libFile = $libFile"

  local linkFile="$binDir/$linkFileName"
  LogDebug "linkFile = $linkFile"

  # Sanity checking
  if [ ! -f "$libFile" ]; then
    LogError "The specified library file $libFile does not appear to exist."
    return 2
  elif [ ! -x "$libFile" ]; then
    LogVerbose "Making $libFile executable."
    Run -r chmod +x "$libFile"
  fi

  if [ -f "$linkFile" ]; then
    Log -n "The link $linkFile already exists. Do you want to overrwrite it [Y/n] (10s)? "
    [ $QUIET ] || read -N 1 -t 10 choice; echo
    [ "${choice,,}" == 'n' ] && return 3 || Run -r rm "$linkFile"
  fi
  
  if [ ! $QUIET ] && [ $interactive ]; then
    read -N 1 -p "Do you want to create a link $linkFile to $libFile (Y/n/a/q)? " choice; echo
    [ "${choice,,}" == 'n' ] && return 10
    [ "${choice,,}" == 'a' ] && unset interactive
    [ "${choice,,}" == 'q' ] && exit 0
  fi

  Run -r ln -s "$libFile" "$linkFile"
  if [ -f "$linkFile" ]; then
    Log "Link created: $linkFile -> $libFile"
    return 0
  else
    LogError "Failed to create link $linkFile -> $libFile"
    return 1
  fi
}

declare -r scriptFile="$1"
if [ -z "$scriptFile" ]; then
  Log -n "No script file specified. Do you want to do them All, get Help, or Quit [A,h,q] (10s)? " 
  [ "$QUIET" ] || read -N 1 -t 10 nextstep; echo
  [ "${nextstep,,}" == 'h' ] && { PrintHelp; exit 0; }
  [ "${nextstep,,}" == 'q' ] && { exit 0; }
  
  # Make a backup of $binDir
  Run -r rm -rf "$binDir.bak"
  Run -r mv "$binDir" "$binDir.bak"
  Run -r mkdir "$binDir"

  declare -a srcDirs
  IFS=$'\n' srcDirs=($(find "$srcDir/" -maxdepth 1 -type d -name "*.shd"))

  for dir in "${srcDirs[@]}"; do
    for script in $(find "$dir/" -maxdepth 1 -executable -type f,l); do
      LinkScript "$script"
    done
  done
else
  LinkScript "$scriptFile"
fi
exit $?
