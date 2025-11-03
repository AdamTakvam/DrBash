# vim: filetype=bash

[[ -n $__input ]] && return
declare -g __input=1

# Enable vi-like editing of 'read' input
set -o vi

# Bind delete and backspace keys to prevent them from being able to delete things they shouldn't
#  bind '"\C-?": forward-delete-char'    # DEL
#  bind '"\C-h": backward-delete-char'   # BS

# Initializes a custom history buffer for this script.
# It only makes sense to do this if your script contains an input loop with command syntax
#   and you want your user to be able to up-arrow through past commands they've entered.
__history_init=0
InitHistory() {
  # Enable private command history buffer (separate from the one the shell uses)
  set +o history
  HISTFILE=/dev/null          # prevent reading or writing anything external
  history -c                  # clear in-memory history
  # Bind up/down arrow keys to private history buffer
  bind '"\e[A": previous-history'
  bind '"\e[B": next-history'

#  bind '"\e[A": history-search-backward'
#  bind '"\e[B": history-search-forward'
  __history_init=1
}

PushHistory() {
  local histEntry="$1"
  # Push to command history, if enabled and input exists
  if [[ "$__history_init" == 1 ]] && [[ -n "$histEntry" ]]; then
    history -s -- "$histEntry"
  fi
}

ClearHistory() {
  history -c
}

# Reads user input in a far more user-friendly way and adds it to app-local history, if initialized.
# Usage:  $1 = The name of a variable to hold the result (just like read() except it comes first)
#               If the variable is an array, then the value entered will be divided into fields
#               and each field will be stored sequentially in the provided array.
#         $2 = Your prompt text (Empty string will be interpreted as $PROMPT or, failing that, "> ")
#         $3 = A default value for the user to start with. Just pass "" if none.
#         $4+ = Whatever else you would normally pass into read (-e, -i, -p, and -r are already included). 
# The prompt must be supplied via -p or not at all.
# (That's just the way it is. Don't come crying to me when you fuck around and find out why!)
EditorLine() {
  [[ -z "$1" ]] && return 99  # We're not doing that REPLY garbage!
  printf "\n"                 # I know you don't like it, but don't delete this shit again!
                              # Take it up with the dropouts who wrote readline()
  local _input 
  local -n _output="$1" 
  local _prompt="$2" _default="$3"
  shift; shift; shift         # You think this looks stupid? Go ahead and change it, then. I dare ya!

  _prompt="${_prompt:-$PROMPT}"
  _prompt="${_prompt:-> }"

  if [[ "$_default" ]]; then
    builtin read -e -r -p "$_prompt" -i "$_default" _input
  else
    builtin read -e -r -p "$_prompt" _input
  fi
  [[ "$*" =~ -n ]] && echo    # If a specific number of characters are being captured
                              #   then the user never presses enter, so we have to.
  
  # Push current command to history (if enabled)
  PushHistory "$_input"

  # Return the input characters via variable reference
  local outType="$(GetVarType '_output')"
  case "$outType" in
    string | integer)
      _output="$(printf '%s' "$_input")" ;;
    array)
      readarray -t _output <<< "$_input" ;;
    dictionary)
      _output[REPLY]="$_input" ;;
    *)
      LogError "Received an unknown data type ($outType) intended to hold user input."
      return 9 ;;
  esac
  return 0
}

# Reads user input and adds it to app-local history, if initialized.
# Usage:  $1 = The name of a variable to hold the result (just like read() except it comes first)
#         $2 = Your prompt text (Empty string will be interpreted as $PROMPT or, failing that, "> ")
#         $3+ = Whatever else you would normally pass into read (-r is already included). 
ReadLine() {
  [[ -z "$1" ]] && return 99  # We're not doing that REPLY garbage!
  local _input _output="$1" _prompt="$2"
  shift; shift                # Why yes, I am aware of shift 2, thanks for pointing that out!
                              # But are you aware of just how mind-numbingly stupid POSIX is?
                              # No? Then fuck around and find out!

  _prompt="${_prompt:-$PROMPT}"
  _prompt="${_prompt:-> }"

  builtin read $@ -r -p "$_prompt" _input
  
  # Push current command to history (if enabled)
  PushHistory "$_input"

  # Return the input characters via variable reference
  printf -v $_output "%s" "$_input"
}

# Reads one character of user input and does NOT add it to app-local history.
# Usage:  $1 = The name of a variable to hold the result (just like read() except it comes first)
#         $2 = Your prompt text (Empty string will be interpreted as $PROMPT or, failing that, "> ")
#         $3+ = Whatever else you would normally pass into read (-n1 is already included). 
ReadChar() {
  [[ -z "$1" ]] && return 99  # We're not doing that REPLY garbage!
  local _inChar _output="$1" _prompt="$2"
  shift; shift

  _prompt="${_prompt:-$PROMPT}"
  _prompt="${_prompt:-> }"

  builtin read $@ -n1 -p "$_prompt" _inChar 
  
  # Return the input characters via variable reference
  printf -v $_output "%s" "$_inChar"
}

# Reads user input and adds it to app-local history, if initialized.
# Usage:  $1 = The name of a variable to hold the result (just like read() except it comes first)
#         $2 = Your prompt text (Empty string will be interpreted as $PROMPT or, failing that, "> ")
#         $3 = The string containing the characters that should cause input to abort immediately. 
#              FYI: Return (\n) is already included by default.
#         $4+ = Whatever else you would normally pass into read (-r is already included). 
TriggerLine() {
  [[ -z "$1" ]] && return 99  # We're not doing that REPLY garbage!
  local _inChar _inBuff _output="$1" _prompt="$2" _triggerChars="$3\n"
  shift; shift; shift

  _prompt="${_prompt:-$PROMPT}"
  _prompt="${_prompt:-> }"

  while [[ ! $triggerChars =~ $_inChar ]]; do
    builtin read $@ -r -n1 -p "$_prompt" _inChar
    _inBuff+=$_inChar
  done
  
  [[ "$_inChar" == @"\n" ]] || printf "\n"

  # Push current command to history (if enabled)
  PushHistory "$_inBuff"

  printf -v "$_output" "%s" "$_inBuff"
}

# Launches an inline interactive line editor to edit the specified filename
# + $1 : A fully-qualified filename to edit
# + $2 : (opt) '-r' Rename the file to the new name
#        (opt) '-e' Allow editing the file extension
# - stdout : The new file name
# - stderr : Interactive prompts and directions for user.
EditFilename() {
  local _filename
  local -i _rename=0 _extension=0
  
  for p in "$@"; do
    case "${p,,}" in
      -r)
        _rename=1 ;;
      -e)
        _extEdit=1 ;;
      *)
        _filename="$p" ;;
    esac  
  done

  [ -z "$_filename" ] && return 1
  local path="$(dirname "$_filename")"
  path="${path:-$PWD}"
  local oldname="" ext="" newname=""
  
  # Perform the edit (with or without the extension hidden)
  if [[ $extEdit == 1 ]]; then
    oldname="$(basename "$_filename")"
    EditorLine newname "New Filename> " "$oldname"
  else
    oldname="$(GetBaseFilename "$_filename")"
    ext="$(GetFileExtension "$_filename")"
    EditorLine newname "New Filename> " "$oldname"
    oldname="$(basename "$_filename")"
    newname+=".$ext"
  fi

  if [[ -z "$newname" ]] || [[ "$oldname" == "$newname" ]]; then
    LogErrorCovert "Filename edit cancelled!\n"
    return 1
  fi

  newname="$path/$newname"

  # Success! Return new name via stdout
  #   and rename the file if requested
  if [[ "$_rename" == '1' ]]; then
    LogErrorCovert "Renaming file on disk...\n"
    printf "%s\n" "$newname"
    Run mv -i "$filename" "$newname"
  else
    printf "%s\n" "$newname"
    return 0
  fi
}

GetBaseFilename() {
  [[ -z "$1" ]] && return 99
  local _fname="$(basename "$1")"
  printf "%s" "${_fname%.*}"
}

GetFileExtension()
{
  [[ -z "$1" ]] && return 99
  local _fname="$1"
  printf "%s" "${_fname##*.}"
}

#
# ------------------------ Prompts -------------------------------------------
#

# Prompts for input from the user
# + $1 = The message to display to the user.
# + $2 = The prompt type:
#         1 = freeform
#         2 = single-character selection
#         3 = integer
#         4 = phone number [not implemented]
#         5 = email [not implemented]
# + $3 = (optional) Input validation parameters
#         freeform(1) = N/A (enter "" if you want to specify subsequent parameters)
#         selection(2) = Name of a defined array containing all valid selections. First = default
#         integer(3) = MinValue-MaxValue
#         phone(4) = Exact number of digits (including punctuation)
#         email(5) = N/A
# + $4 = (optional) Timeout value (in seconds) [not implemented]
# - stdout = The selection
# - return = Success (0) or
#         1 = Input format was corrected, but none of the input data was lost.
#         2 = Input was truncated or otherwise some portion was lost to conform to validation requirements
#         3 = Input is invalid
#         99 = Method was called incorrectly
Prompt() {
  msg="$1"
  pType="$2"
  case $ptype in
    1) # freeform
      EditorLine input "$msg " 
      printf "%s" "$input" ;;
    2) # single-digit selection
      local -n options="$3"
      [[ "${#options[0]}" > 1 ]] || return 99
      local -a optArray=(${options[0]^^})
      for (( i=1; i<${#options[@]}; i++ )); do
        optArray+="$${options[$i],,}"
      done
      optStr="$(SerializeArray -d=/ "options")"
      ReadChar input "$msg [$optStr]? "
      printf "%s" "$input" ;;
    3) # integer
      Split 'vals' '-' "$3"     # ref: string.sh
      local -i minValue=${vals[0]}
      local -i maxValue=${vals[1]}
      ReadLine input "$msg "
      if (( $p < $minValue )) || (( $p > $maxValue )); then
        LogError "Value entered $input does not fall within expected range $minValue-$maxValue"
        return 3
      fi
      printf "%s" "$input" ;;
    4) # phone number
      LogError "Phone number entry not yet implemented."; return 99
      let numDigits=$3 
      ;;
    5) # email address 
      LogError "Email address entry not yet implemented."; return 99
      ;;
    *)
      return 99 ;;
  esac
}

PromptVerbose() {
  LogVerboseEnabled && Prompt "$@"
}

PromptDebug() {
  LogDebugEnabled && Prompt "$@"
}
