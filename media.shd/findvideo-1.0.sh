#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
source "${USERLIB:-$HOME/lib}/arrays.sh"

CanRun videoinfo
if [ ! $? ]; then
  LogError "Error: Cannot resolve dependency: videoinfo"
  exit 1
fi

declare -r APPNAME="findvideo"

PrintHelp() {
  tabs 4
  Log "Finds all video files in the current directory tree that match the supplied regular expression."
  Log "Additional actions are available in interactive mode (default if output not redirected)." 
  Log "This command plays nice with output redirection. So don't be afraid to redirect the output."
  Log
  Log "$(Header "Usage:") $APPNAME [FLAGS] PATTERN..."
  Log
  LogHeader "FLAGS:"
  LogTable "\t-h\tDisplay this help text.
  \t-i\tRun in interactive mode (default).
  \t-I\tDo not run in interactive mode (just print results and exit).
  \t-r\tSearch in subdirectories (default).
  \t-R\tDo not search subdirectories.
  $(LogParamsHelp)"
  Log
  Log "$(Header "PATTERN")\tAny extended regular expression(s) that matches any part of the desired file name,"
  Log "\t\tor a quoted set of words to look for exactly as given,"
  Log "\t\tor an unquoted set of words to look for in any order anywhere in the filename (logical AND)."
  Log "\t\tNote: PATTERN is case-insensitive."
  Log "\t\tNote: $ is not supported in regular expressions."
  Log
  DisplayPromptHelp
  Log
  LogHeader "Examples:"
  Log "\tSearches that will find \"The Chronicles of Narnia: The Lion, The Witch, And The Wardrobe.mp4\":"
  Log "\t* $APPNAME \".*narnia.*witch.*wardrobe\""
  Log "\t* $APPNAME \"the lion\""
  Log "\t* $APPNAME narnia wardrobe witch"
  Log
}

DisplayPromptHelp() {
  LogHeader "The Prompt:"
  Log "\tThe prompt is where you are expected to enter a letter corresponding to an action"
  Log "\tand a number corresponding to a file you would like that action to be performed on or with."
  Log "\t- OR - a parameter that directs the action as described below."
  Log
  Log "\tFor example:" 
  Log "\t\tIf you want to get the properties of the fourth search result: $(ColorText LGREEN 'p 4')"
  Log "\t\tIf you want to filter the results to include only those that include the word bunny: $(ColorText LGREEN 'f bunny')" 
  Log
  LogHeader "Actions:"
  LogTable "\tp #\tGet media properties
  \td #\tDelete the file
  \t\tWarning: Does not prompt for confirmation.
  \t\tWill attempt to use trash if you have it installed.
  \tf <expr>\tFilter these results to only those matching regex <expr>
  \t\tIt's the same behavior as if you had specified an addition term on the command line.
  \tn #\tNormalize the filename (coming soon!)\n"
}

# Applies the values in the SEARCHTERMS array and returns the matching set of files in the CWD.
# + $1 = Name of the variable used to hold the resulting array of filenames
GetFileMatches() {
  local -n results="$1"
  local -i init=0

  for searchTerm in "${SEARCHTERMS[@]}"; do
    LogVerbose "Applying search term: \"$searchTerm\""

    if [ $init == 0 ]; then
      if [ $searchSubs == 1 ]; then
        IFS=$'\n' results=($(find . -type f -regextype egrep -iregex ".*$searchTerm.*"))
      else
        IFS=$'\n' results=($(find . -maxdepth 1 -type f -regextype egrep -iregex ".*$searchTerm.*"))
      fi
      SortArray "results"
      init=1
      LogDebug "The search found ${#results[@]} matches."
    else
      local -a results2=()

      for searchResult in "${results[@]}"; do
        matchingResult="$(echo "$searchResult" | grep -Ei "$searchTerm")"
        [ "$matchingResult" ] && results2+=("$matchingResult")
      done

      results=()
      if [ ${#results2[@]} == 0 ]; then
        LogVerboseError "It looks like we filtered out all of the results!"
        return
      else
        for r in "${results2[@]}"; do
          results+=("$r")
        done
      fi
      LogVerbose "Performed incremental filter and am left with ${#results[@]} matches."
    fi
  done
}

DisplayResults() {
  LogVerbose "Search Terms (DisplayResults) = $(SerializeArray -q -d=, -dS SEARCHTERMS)"

  declare -ag videos
  GetFileMatches 'videos'
  if [ ${#videos[@]} == 0 ]; then
    LogError "No matches found for case-insensitive search term(s): $(SerializeArray -q -d=, -dS SEARCHTERMS)"
    return
  fi
  
  LogVerbose "GetFileMatches returned ${#videos[@]} results."

  if [ $interactive == 1 ]; then
    # Format results for human consumption
    LogHeader "\nMatches:"
    for (( i=0; i < ${#videos[@]}; i++ )); do
      Log "$i) ${videos[$i]}"
    done
  else # Format results for computer consumption.
    for file in "${videos[@]}"; do
      echo "$file"
    done
  fi
}

DoCommand() {
  local FNAME="DoCommand()"
  local action="$1"
  local param="$2"

  [ -z "$action" ] && return

  LogDebug "$FNAME.action = $action"
  LogDebug "$FNAME.param = $param"

  if [ -z "$param" ]; then
    # Convenience shortcut
    local -i numResults="${#videos[@]}"
    LogDebug "$FNAME.numResults = $numResults"
    
    if [ "$numResults" == 1 ]; then
      param=0
    elif [ "$action" == "p" ] && (( "$numResults" <= 10 )); then
      ((  numResults-- ))
      for param in $(seq 0 $numResults); do
        LogDebug "Calling $FNAME recursively with: i $param"
        DoCommand p $param
      done
      return 0
    else
      LogError "Error: No match index specified." 
      DisplayPromptHelp
      return 1
    fi
  fi
        
  local filename="${videos[$param]}"
  if [ "$filename" ]; then
    case "$action" in
      d)            # Delete
        [ "$(/bin/which trash)" ] \
          && Run trash "$filename" \
          || Run rm "$filename"
        displayResults=1 ;;
      p)            # Properties
        Log "$filename:"
        Run videoinfo "$filename" ;;
      f)            # Filter
        declare -g regex="$param"
        SEARCHTERMS+=("$regex")
        displayResults=1 ;;
      "")
        DisplayPromptHelp ;;
      *)
        LogError "Invalid action: $action"
        DisplayPromptHelp ;;
    esac
  else
    LogError "Error: Invalid match index: $param"
  fi
}

ShowMenu() {
  Log -n "\nEnter a command, or h for help, or q to quit: " 
  read cmd
  local action="$(echo $cmd | awk '{ print $1 }')" 
  local s_index="$(echo $cmd | awk '{ print $2 }')"  

  LogDebug "ShowMenu().action = $action"
  LogDebug "ShowMenu().s_index = $s_index"

  case "${action,,}" in
    p | d | f)
      DoCommand "$action" "$s_index" ;;
    n)
      LogError "Error: This feature is not yet implemented." ;;
    q)
      LogVerbose "--- Quitting..."
      quit=1 ;;
    "" | h | help)
      DisplayPromptHelp ;;
    *)
      LogError "Error: Invalid action: $action"
      DisplayPromptHelp ;;
  esac
}

# Parse the command line
declare -ag SEARCHTERMS=()
declare -g interactive=1 searchSubs=1

ParseCLI() {
  LogDebug "ParseCLI parameters: $@"

  [ -z "$1" ] && { PrintHelp; exit 1; }

  for p in "$@"; do
    if [[ "$p" =~ ^- ]]; then
      case "$p" in
        -h)
          PrintHelp
          exit 0 ;;
        -i)
          interactive=1 ;;
        -I)
          interactive=0 ;;
        -s)
          searchSubs=1 ;;
        -S)
          searchSubs=0 ;;
      esac
    else
      SEARCHTERMS+=("$p")
    fi
  done
  
  # Disable interactive mode if our output is being piped to another command.
  if [ ! -t 1 ]; then 
    LogVerbose "Disabling interactive mode because stdout appears to be redirected"
    interactive=0
  fi

  # Disable interactive mode if we're being sourced by another script.
  if [ "$BASH_SOURCE" != "$0" ]; then
    LogVerbose "Disabling interactive mode because we appear to be sourced ("$BASH_SOURCE" != "$0")"
    interactive=0
  fi
  declare -r interactive
  
  [ ${#SEARCHTERMS[*]} == 0 ] && { PrintHelp; exit 1; }
#  declare -r SEARCHTERMS
  LogVerbose "Search Terms (ParseCLI) = $(SerializeArray -q -d=, -dS SEARCHTERMS)"
}

InteractiveLoop() {
  local -i displayResults=1 showMenu=1 quit=0

  while [ $quit == 0 ]; do
    if [ $displayResults == 1 ]; then
      DisplayResults
      [ $? != 0 ] && exit $?
      displayResults=0
    fi

    if [ $showMenu == 1 ]; then
      ShowMenu
    fi
  done
}

ParseCLI "$@"

if [ $interactive == 0 ]; then
  DisplayResults
else
  InteractiveLoop
fi
