# Protect against being sourced multiple times
[ $__editfilename ] && return 0
__editfilename=1

source "${USERLIB:-$HOME/lib}/general.sh"

Require zsh

APPNAME="editfilename"

# Launches an inline interactive line editer (vared)
#   to edit the specified list of filenames
# + $1 : The name of an array containing the fully-qualified filnames to edit
# - stdout : The new filenames (one per line)
# - stderr : Interactive prompts and directions for user.
# - filesystem : Indicated filenames will be renamed if the user edits the names given
EditFilenames() {
  [ "$1" ] || return 1
  local -n _filenames="$1"

  local -i retVal=1
  for file in "${_filenames[@]}"; do
    if [ "$file" == "${_filenames[0]}" ]; then
      EditFilename "$file" -r
    else
      EditFilename "$file" -r -n  # Only print the directions the first time
    fi
    [ $? == 0 ] && retVal=0   # Success(0) means that the file was renamed successfully
                              # So return success if any were renamed
  done
  return $retVal
}

# Launches an inline interactive line editer (vared)
#   to edit the specified filename
# + $1 : A fully-qualified filname to edit
# + $2 : (opt) '-r' to go ahead and rename the file to the new name also
# + $3 : (opt) '-n' to suppress printing the edit instructions
# - stdout : The new file name
# - stderr : Interactive prompts and directions for user.
EditFilename() {
  local filename
  local -i rename=0 instructions=1
  
  for p in "$@"; do
	  case "${p,,}" in
	    -r)
	      rename=1 ;;
	    -n)
	      instructions=0 ;;
	    *)
        filename="$p" ;;
	  esac  
	done

  [ -z "$filename" ] && return 1
  local path="$(dirname "$filename")"
  [ -z "$path" ] && path='.'
  local oldname="$(basename "$filename")"
  export newname="$oldname"  # Must export in order for Zsh to be able to read the value
  
  LogVerboseError "Editing: $oldname"
  if [ "$instructions" == 1 ]; then
    LogError "Instructions (zsh vared):"
    LogError "\t- Press 'i', make edits, then press '<enter>'"
    LogError "\t- Press '<enter>' without making edits to cancel."
    LogError "\t- If you want to cancel after making edits, press <CTRL>-C"
    LogError "Tips:"
    LogError "\t- Use <backspace> instead of <delete>"
    LogError "\t- If it seems to have lost its mind, you are in vi command mode. Just do vi shit and you'll get through this!\n"
  fi

  newname="$(zsh -c 'vared newname; echo -n "$newname"')"
  
  if [ "$oldname" == "$newname" ]; then
    LogError "Filename edit cancelled!\n"
    return 1
  else
    LogVerboseError "New Filename = $newname"      

    if [ "$rename" == '1' ]; then
      LogError "Renaming file on disk...\n"
      Run mv -i "$path/$oldname" "$path/$newname"
      return $?
    fi
  fi

  echo "$path/$newname"
}

