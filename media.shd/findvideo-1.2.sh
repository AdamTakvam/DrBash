#!/bin/bash

# source "${USERLIB:-$HOME/lib}/logging.sh"
# source "${USERLIB:-$HOME/lib}/general.sh"
source "${USERLIB:-$HOME/lib}/run.sh"
source "${USERLIB:-$HOME/lib}/arrays.sh"
source "${USERLIB:-$HOME/lib}/editfilename.sh"

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
  Log "$(Header "Usage:") $APPNAME [FLAGS] [OPTIONS] PATTERN..."
  Log
  LogHeader "FLAGS"
  LogTable "\t-h\tDisplay this help text.
  \t-i\tRun in interactive mode (default).
  \t-I\tDo not run in interactive mode (just print results and exit).
  \t-r\tSearch in subdirectories (default).
  \t-R\tDo not search subdirectories.
  $(LogParamsHelp)"
  Log
  LogHeader "OPTIONS"
  LogTable "\t-d=PATH\tThe directory in which to conduct the search (default = $PWD)."
  Log
  Log "$(Header "PATTERN")\tAny extended regular expression(s) that matches any part of the desired file name,"
  Log "\t\tor a quoted set of words to look for exactly as given,"
  Log "\t\tor an unquoted set of words to look for in any order anywhere in the filename (logical AND)."
  Log "\t\tNote: PATTERN is case-insensitive."
  Log "\t\tNote: $ is not supported in regular expressions."
  Log
  LogHeader "Notes:"
  LogTable "\t1.\tIf you have sudo privileges, then all file operations will be executed as root.
  \t\tWhen this is the case, the message \"Running with elevated privileges\" is displayed in green.
  \t\tIf this behavior is not desired, then run this script as a less privileged user.
  \t2.\tIf the output of this script is redirected anywhere (e.g $APPNAME > media.txt) or if you source this script from another (IYKYK), then interactive mode is disabled even if you specify the -i command-line option.
  \t3.\tEven thouggh this command was created for use in curating a media file collection, there is nothing about it that limits it to only media files. It should work great with any arbitrary collection of files."
  Log
  LogHeader "Command Examples:"
  Log "\tSearches that will find \"The Chronicles of Narnia: The Lion, The Witch, And The Wardrobe.mp4\":"
  Log "\t* $APPNAME \".*narnia.*witch.*wardrobe\""
  Log "\t* $APPNAME \"the lion\""
  Log "\t* $APPNAME narnia wardrobe witch"
  Log
  DisplayPromptHelp
}

DisplayPromptHelp() {
  tabs 4
  LogHeader "== The Prompt (interactive mode) =="
  Log "\tThe prompt is where you are expected to enter a letter corresponding to an action"
  Log "\tand zero or more parameters as described below."
  Log
  LogHeader "Actions:"
  LogTable "\tr\tRefresh/Redisplay the list of matches (no parameters).
  \ts PATTERN\tInitiate an entirely new search using PATTERN.
  \tp #...\tGet media properties. Specify one or more space-separated file indices (e.g. p 1 2 3 4).
  \tdder #\tDelete the file
  \t\tNote: Will attempt to use trashcan (script) then the trash (command) before resorting to /bin/rm.
  \tf PATTERN\tFilter the current results to only those also matching PATTERN.
  \t\tIt's the same behavior as if you had specified an additional term on the command line.
  \te #...\tEdit the name of one or more files.
  \tn #\tNormalize the filename (coming soon!)\n"
  Log
  LogHeader "Action Parameters:"
  LogTable "\t#\tOne or more space-delimited numbers corresponding to file(s) that you would like the action performed on.
  \tPATTERN\tHas the same meaning as given in the main command help page (or just above if you're already there).\n"
  Log
  LogHeader "Action Examples:" 
  Log "\t1. To get the properties of the fourth search result: $(ColorText LGREEN 'p 4')"
  Log "\t2. To filter the results to include only those that also include the word 'bunny': $(ColorText LGREEN 'f bunny')" 
  Log "\t3. To start a new search for just the first 2 Matrix movies (quotes matter!): $(ColorText LGREEN 's "Matrix [12]"')" 
  Log
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
        IFS=$'\n' results=($(find "$rootDir" -type f -regextype egrep -iregex ".*$searchTerm.*"))
      else
        IFS=$'\n' results=($(find "$rootDir" -maxdepth 1 -type f -regextype egrep -iregex ".*$searchTerm.*"))
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
        showMenu=0
        return 1
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
  declare -r FNAME="DisplayResults()"
  declare -ag videos

  LogVerbose "Search Terms (DisplayResults) = $(SerializeArray -q -d=, -dS SEARCHTERMS)"

  GetFileMatches 'videos'

  LogDebug "GetFileMatches() returned ${#videos[@]} results."

  if [ ${#videos[@]} == 0 ]; then
    LogError "No matches found for case-insensitive search term(s): $(SerializeArray -q -d=, -dS SEARCHTERMS)"
    showMenu=0
    return 1 
  fi
  
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
  local action="$1"; shift; [ -z "$action" ] && return
  local -a f_indices=("$@")
  local -a filenames=()

  case "$action" in
    e | p | d)
	    # Get the filenames corresponding to the indices passed in
	    for i in ${f_indices[@]}; do
	      LogDebug "Number of items in videos[] = ${#videos[@]}"
	      fname="${videos[$i]}"
	      
	      if [ "$fname" ]; then
	        filenames+=("$fname")
	      else
	        LogError "Error: Invalid match index: $i\n"
	        displayResults=1
	        return 1
	      fi
	    done
	    unset fname ;;
  esac

  LogDebug "$FNAME.action = $action"
  LogDebug "$FNAME.f_indices = $(SerializeArray f_indices)"
  LogDebug "$FNAME.filenames = $(SerializeArray -de filenames)"

  case "$action" in
    d)              # Delete
      read -n1 -p "Are you sure that you want to delete the specified files (this action might be irreversible) (Y/n)? " choice
      if [ "${choice,,}" != 'n' ]; then 
	      for file in "${filenames[@]}"; do
	        trash=0
	        if [ "$(/bin/which trashcan)" ]; then
	          trash=1
	          Run $runParam trashcan "$file"
	        elif [ "$(/bin/which trash)" ]; then
	          trash=1
	          Run $runParam trash "$file"
	        fi
	      
	        # If it's still there, bypass trash and just get it gone! 
	        if [ -f "$file" ]; then
	          [ "$trash" == 1 ] && LogError "$(ColorText YELLOW "Moving $file to trash failed. Attempting permanent deletion...")"
	          Run $runParam /bin/rm "$file"
	        fi
	
	        if [ -f "$file" ]; then
	          LogError "$(ColorText YELLOW "All attempts to delete $file have failed!")"
	        else
	          Log "$(ColorText LGREEN "$file deleted\n")"
	        fi
	        unset trash
	      done
	
	      unset file
	      displayResults=1
      fi ;;
    p)              # Properties
      for file in "${filenames[@]}"; do
        Run $runParam videoinfo "$file"; echo 
      done ;;
    f | s)              # Filter or new Search
      if [ -z "$1" ]; then
        LogError "$(ColorText LRED "Error: No filter/search parameter supplied")"
        sleep 5
      elif [ $action == 'f' ]; then
        SEARCHTERMS+=("$@")   # Append new search terms to existing set
      else
        SEARCHTERMS=("$@")    # Create new set using supplied terms
      fi 
      displayResults=1 ;;
    e)                # Edit
      echo
      EditFilenames "filenames"   # Defined in lib/editfilenames.sh
      displayResults=1 ;;
    r)                # Refresh results
      DisplayResults ;;
    "")
      DisplayPromptHelp ;;
    *)
      LogError "Invalid action: $action"
      DisplayPromptHelp ;;
  esac
}

ShowMenu() {
  declare FNAME="ShowMenu()"

  Log -n "\nEnter a command, or h for help, or q to quit: " 
  read cmd
  
  local action=${cmd::1} 
  LogDebug "$FNAME.action = ${action:-<not set>}"

  local -a indices=()
  indStr="${cmd:2}"
#  read -a indices <<< "$indStr" 
#  LogDebug "$FNAME.#indices = ${#indices[@]}"
#  LogDebug "$FNAME.indices() = $(SerializeArray -d=, -dS indices)"

#  DeserializeArray -ds -a='indices' "${cmd:2}"  
#  LogDebug "$FNAME.#indices = ${#indices[@]}"
#  LogDebug "$FNAME.indices() = $(SerializeArray -d=, -dS indices)"

  awkStr="$(echo "${indStr}" | awk '{ print $1 "\n" $2 }')"
  LogDebug "$FNAME.awkStr = $awkStr"
  IFS=$'\n' indices=($awkStr)
  LogDebug "$FNAME.#indices = ${#indices[@]}"
  LogDebug "$FNAME.indices() = $(SerializeArray -d=, -dS indices)"

  case "${action,,}" in
    p | d | f | e | r | s)
      DoCommand "$action" "${indices[@]}" ;;
    p* | d* | f* | e* | s*)
      # Just a convenience so that you can get away with 
      #   forgetting the space between the command and index
      action="${action::1}"   # The first letter
      indices=(${action:1})   # Everything after the first letter
      DoCommand "$action" "${indices[@]}" ;;
    n)
      # Normalize filename
      # TODO: Run media-fixtitle and media-fixtags only on the requested file.
      #   Modify those scripts to recognize a file being passed in as opposed to a directory.
      # Show the user the new filename.
      # Then rerun their query (which might not contain the normalized file anymore).
      LogError "$(ColorText LRED "Error: This feature is not yet implemented.")" ;;
    q)
      LogVerbose "--- Quitting..."
      quit=1 ;;
    "" | h | help)
      DisplayPromptHelp ;;
    *)
      LogError "$(ColorText LRED "Error: Invalid action: $action")"
      DisplayPromptHelp ;;
  esac
}

# Parse the command line
declare -ag SEARCHTERMS=()
declare -ig interactive=1 searchSubs=1 
declare -g runParam='-u'
declare rootDir='.'

ParseCLI() {
  LogDebug "ParseCLI parameters: $@"

  [ -z "$1" ] && { PrintHelp; exit 1; }

  if [ "$(HasSudo)" ]; then
    runParam='-r'
    Log "$(ColorText GREEN "Running with elevated privileges")"
  fi

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
        -d)
          rootDir="${p#*=}" ;;
        *($(LogParamsCase))* )
          : ;;
        *)
          LogError "Invalid parameter: $p"
          PrintHelp
          exit 1
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
