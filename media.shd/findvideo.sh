#!/bin/bash

source "${DRB_LIB}/drbash.sh"
source "$DRB_MEDIA_LIB/playlist.sh"
source "$DRB_MEDIA_LIB/media-props.sh"
source "$DRB_MEDIA_LIB/media-config.sh"

set -f        # Disables globbing

if ! CanRun videoinfo; then
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
  LogTable "$(Header "Usage:")\t$APPNAME [FLAGS] [OPTIONS] PATTERN...
  \t$APPNAME --version
  \t$APPNAME -h"
  Log
  LogHeader "FLAGS:"
  LogTable "\t-f\tDisplay the full path to media files in search results.
  \t-F\tDo not display the path to the media directory in search results. (default)
  \t-h\tDisplay this help text.
  \t-i\tRun in interactive mode (default).
  \t-I\tDo not run in interactive mode (just print results and exit).
  \t-r\tSearch in subdirectories (default).
  \t-R\tDo not search subdirectories.
  $(LogParamsHelp)"
  Log
  LogHeader "OPTIONS:"
  LogTable "\t-d=PATH\tThe directory in which to conduct the search (default = $PWD)."
  Log
  Log "$(Header "PATTERN")\tAny extended regular expression(s) that matches any part of the desired file name,"
  Log "\t\tor a quoted set of words to look for exactly as given,"
  Log "\t\tor an unquoted set of words to look for in any order anywhere in the filename (logical AND)."
  Log "\t\tNote: PATTERN is case-insensitive."
  Log "\t\tNote: $ is not supported in regular expressions."
  Log
  LogHeader "Environment Variables:"
  LogTable "\tDRB_MEDIA_REPOSEARCH\ttrue = Always search the configured repository directory regardless of where the command is invoked.
  \t\t0 or unset = Search in the current directory.
  \t\tNote: The -d flag will override this setting.
  \tDRB_MEDIA_REPO\tThe path to the repository, if DRB_MEDIA_REPOSEARCH=true
  \tDRB_MEDIA_PLAYLISTS\tThe path to a writeable directory where playlists will be saved."
  Log
  LogHeader "Notes:"
  LogTable "\t1.\tIf you have sudo privileges, then all file operations will be executed as root.
  \t\t  When this is the case, the message \"Running with elevated privileges\" is displayed in green.
  \t\t  If this behavior is not desired, then run this script as a less privileged user.
  \t2.\tIf the output of this script is redirected anywhere (e.g $APPNAME > media.txt) or if you source this script from another, 
  \t\t  then interactive mode is disabled even if you specify the -i command-line option. 
  \t\t  The output format is also stripped down for easy piping. You're welcome!"
  Log
  LogHeader "Command Examples:"
  Log "\tSearches that will find \"The Chronicles of Narnia: The Lion, The Witch, And The Wardrobe.mp4\":"
  Log "\t* $APPNAME \".*narnia.*witch.*wardrobe\""
  Log "\t* $APPNAME \"the lion\""
  Log "\t* $APPNAME narnia wardrobe witch"
  DisplayPromptHelp
}

DisplayPromptHelp() {
  tabs 4
  Log
  LogHeader "== The Prompt (interactive mode) =="
  Log "\tThe prompt is where you run actions against a result set."
  Log "\tActions consist of a letter designation followed by one or more parameters as described below."
  Log
  LogHeader "Conventions:"
  LogTable "\tlower-case\tLiteral value.
  \tUPPER-CASE\tA parameter type as defined below.
  \t#...\tA list of search result identifiers separated by spaces (e.g. 1 2 3 4).
  \t[PARAM]\tPARAM is optional.
  \t'quotes'\tAny value containing spaces must be quoted."
  Log
  LogHeader "Actions:"
  LogTable "\ta [PATH]\tCreate an archive of the result set at location PATH.
  \t\tPATH must be an absolute POSIX path on the server. If no directory exists at that location, one will be created.
  \t\tIf not specified, defaults to \$DRB_MEDIA_REPO\<search terms>
  \tc TYPE\tOpen the configuration file corresponding to TYPE in your default text editor.
  \tc TYPE VALUE\tAdd a permanent file normalization rule.
  \td #...\tDelete the file(s). Prompts for confirmation on each one.
  \t\tNote: Will attempt to use trashcan (script) then the trash (command) before resorting to /bin/rm.
  \te #...\tEdit the name of one or more files.
  \tf PATTERN\tFilter the current results to only those also matching PATTERN.
  \t\t(It's the same behavior as if you had specified an additional term in the original query.)
  \tl\tCreate a Windows Media Player compatible playlist (.m3u8) from your search results.
  \t\tThe playlist title will be your search query and it will fail if you have no configured share mapping.
  \tl TITLE\tCreate a playlist from your search results named TITLE.
  \t\tPlaylist creation will fail if you haven't already configured at least one drive nmapping.
  \tl TITLE PATH=DRIVE_LETTER|UNC|URL\tCreate a playlist from your search results named TITLE using the specified drive mapping.
  \tl ?\tGet more help using the playlist feature.
  \tn\tApply file normalization rules (set via action 'a') to all files in result set.
  \tn #...\tApply file normalization rules to the specified files.
  \t\tIf you want to apply the rules to a set of files in a staging area and merge them into your main repo,
  \t\t  exit this program and run: mediamerge
  \tp\tShow media properties for all search results ordered and color-grouped by runtime.
  \tp #...\tGet media properties. Specify one or more file indices (e.g. p 1 2 3). Results in the order you specified, no color.
  \tr\tRefresh/Redisplay the list of matches.
  \ts PATTERN\tInitiate an entirely new search using PATTERN.
  \tu\tToggle between file and URL style output.
  \tu [PATH=DRIVE_LETTER|UNC|URL]\tSet a path mapping (equates a path on the server with something you can access from a client)" 
  Log
  LogHeader "Parameter Types:"
  LogTable "\tPATTERN\tHas the same meaning as given in the main command help page (or just above if you're already there).
  \tTITLE\tWhat you want to call the playlist [default: your search terms].
  \tPATH\tAn absolute (i.e. starts with a /) directory location (from the server's perspective) [default: Samba config tags].
  \tDRIVE_LETTER\tThe letter of a mapped network drive containing the media (from the client's perspective).
  \tUNC\tThe Windows SMB path to a network share containing the media. Remember to double-up your backslashes (see example below).
  \tURL\tThe http(s):// style path to the media. 
  \tVALUE\tA literal value.
  \tEXPR\tAn extended regular expression (formatted for sed -E).
  \tTYPE\tThe name of a filename normalization rule set. 
  \t\tIf no parameters are supplied, the specified ruleset is opened in the default text editor.
  \t\tIf a parameter is given, a corresponding rule is added (permanently)." 
  Log
  HelpNormalizationTypes
  Log
  LogHeader "Examples:" 
  Log "\t1. To get the properties of the fourth search result: $(ColorText LGREEN 'p 4')"
  Log "\t2. To filter the results to include only those that also include the word 'bunny': $(ColorText LGREEN 'f bunny')" 
  Log "\t3. To start a new search for just the first 2 Matrix movies (quotes matter!): $(ColorText LGREEN 's "Matrix [12]"')" 
  Log "\t4. To generate a playlist from the current matches: $(ColorText LGREEN 'l "My Playlist" /share/videos/=Z')"
  Log "\t5. To generate a playlist from the current matches: $(ColorText LGREEN 'l "My Playlist" /share/videos/=https://myserver/videos/')"
  Log "\t6. To generate a playlist from the current matches: $(ColorText LGREEN 'l "My Playlist" /share/videos/=\\\\\myserver\\Videos\\')"
  Log "\t7. To automatically delete all files with a .tmp extension from the staging area (the next time media files are processed): $(ColorText LGREEN 'a del .tmp$')"
  Log "\t8. To add a file deletion rule: $(ColorText LGREEN 'c file-delete "Tom Green"')" 
  Log "\t9. To edit global configuration: $(ColorText LGREEN 'c config')" 
  Log
}

HelpNormalizationTypes() {
  Run $DRB_BIN/drbashctl -h
}

# Meet: The Globals...
declare -ag SEARCHTERMS=()    # What you're looking for
declare -ig interactive=1     # Is this session capable of interactivity? (read-only) 
declare -g runParam='-u'      # -u = user permissions
                              # -r = root permissions
declare -ig searchSubs=1      # Should we look in subdirectories also?
declare -ig displayURLs=0     # Should the results include URLs to the media files?
declare -ag videos=()         # The results
declare -ig refreshResults=1  # Do we need to (re)run the search?
declare -ig displayResults=1  # Does the result list need to be (re)displayed?
declare -ig showMenu=1        # Should the menu be shown?
declare -ig menuMode=0        # 0 = interactive + results found for initial query
                              # 1 = from then on, don't bail if a query returns no results.
declare -ig quit=0            # Are we done yet?
# Note: MEDIA_ROOT and DISPLAY_FULL_PATH are defined in media-props.sh

# Translates reasonable user assumptions into the equivalent patterns to appease find
# + $1 = The search term to be converted
# - stdout = The converted search term
FormatRegex() {
  local _regex="$1"

  if [[ -n "$_regex" ]]; then
    [[ "${_regex::1}" == ^ ]] \
      && _regex=".*/${_regex:1}" \
      || _regex=".*$_regex"

    [[ "${_regex: -1}" == $ ]] \
      && _regex="${_regex:: -1} \[.*" \
      || _regex="$_regex.*"
    
    printf "%s" "$_regex"
  fi
}

# Applies the values in the SEARCHTERMS array and returns the matching set of files in the CWD.
# + $1 = Name of the variable used to hold the resulting array of filenames
GetFileMatches() {
  local -n results="$1"
  local -i init=0

  for searchTerm in "${SEARCHTERMS[@]}"; do
    if [[ -n "$searchTerm" ]]; then
      LogVerbose "Applying search term: \"$searchTerm\""
  
      searchTerm="$(FormatRegex "$searchTerm")"
  
      if [ $init == 0 ]; then
        if [ $searchSubs == 1 ]; then
          Split results $'\n' "$(find "$MEDIA_ROOT" -type f -regextype egrep -iregex "$searchTerm" 2>/dev/null)"
        else
          Split results $'\n' "$(find "$MEDIA_ROOT" -maxdepth 1 -type f -regextype egrep -iregex "$searchTerm" 2>/dev/null)"
        fi
        # LogVerbose "The search found ${#results[@]} matches (unsorted)."
        SortArray "results"
        init=1
        # LogVerbose "The search found ${#results[@]} matches (sorted)."
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
    fi
  done
}

DisplayResults() {
  displayResults=0

  if [[ $refreshResults == 1 ]] || [[ ${#videos[@]} == 0 ]]; then
    LogVerbose "Search Terms (DisplayResults) = $(SerializeArray -q -d=, -dS SEARCHTERMS)"
    GetFileMatches 'videos'
    LogDebug "GetFileMatches() returned ${#videos[@]} results."
  fi

  if ! IsEmptyArray SEARCHTERMS; then
    if [[ ${#videos[@]} == 0 ]]; then
      LogError "No matches found for case-insensitive search term(s): $(SerializeArray -q -d=, -dS SEARCHTERMS)"
      if [ "$menuMode" == 0 ]; then
        showMenu=0
        return 1
      else
        return 0
      fi
    elif [[ $interactive == 1 ]]; then
      # Format results for human consumption
      LogHeader "\nMatches:"
      for (( i=0; i < ${#videos[@]}; i++ )); do
        Log -n "$i) "
        [[ $displayURLs == 1 ]] && Log "$(GetURL "${videos[$i]}")" \
                                || Log "$(FormatFilename "${videos[$i]}")"
      done
    else # Format results for computer consumption.
      for file in "${videos[@]}"; do
        Log -l "$file"
      done
    fi
  else # Ran the script with no parameters? Give 'em a prompt!
    showMenu=1
  fi
  return 0
}

DoCommand() {
  local -l action="$1"; shift 
  local -a result_indices=("$@")
  local -a filenames=()

  [ -z "$action" ] && return

  case "$action" in
    e | o | p | d)
      # Convenience mode
      case "$action" in
        o | p)
          if [[ 0 == "${#result_indices[@]}" ]]; then
            local -i q=$(( ${#videos[@]} - 1 ))
            result_indices=($(seq 0 $q))
            unset q
          fi ;;
      esac

      # Get the filenames corresponding to the indices passed in
      for i in ${result_indices[@]}; do
        LogDebug "Number of items in videos[] = ${#videos[@]}"
        fname="${videos[$i]}"
        
        if [ "$fname" ]; then
          filenames+=("$fname")
        else
          LogError "Invalid match index: $i\n"
          SetRefreshResultsFlag
          return 1
        fi
      done
      unset fname ;;
  esac

  if LogDebugEnabled; then
    LogDebug "action = $action"
    LogDebug "filenames = $(SerializeArray -de filenames)"
  fi

  case "$action" in
    a)              # Archive
      local path="${1:-$DRB_MEDIA_REPO/${SEARCHTERMS[@]}}"
      Run $runParam mkdir -p "$path"
#      Log "Archiving [          ]"; printf "%b" "\b\b\b\b\b\b\b\b\b\b\b"
      for v in "${videos[@]}"; do
        Run $runParam cp "$v" "$path/"
      done
      Log "Search results have been archived to $path"
      unset v path ;;
    c)              # Configure
      Configure "$@" ;;
    d)              # Delete
      if DoDeleteCommand "filenames"; then
        SetRefreshResultsFlag
      fi ;;
    e)              # Edit
      echo
      for filename in "${filenames[@]}"; do
        EditFilename -r "$filename" >/dev/null
      done
      SetRefreshResultsFlag ;;
    f)              # Filter results
      if [ -z "$1" ]; then
        LogError "No filter parameters supplied"
      else
        AddSearchTerms "$@" 
      fi ;;
    l)              # Create playlist      
      LogDebug "$FNAME: \$1 = $1 | \$2 = $2"
      DoPlaylistCommand "$@" ;;
    n)
      Normalize 'filenames'
      SetRefreshResultsFlag ;;
    o)              # Properties (suspected duplicates only)
      GetFileProps 'filenames' 1 ;;
    p)              # Properties
      GetFileProps 'filenames' 0 ;;
    r)              # Refresh results
      SetRefreshResultsFlag ;;
    s)              # New search
      if [ -z "$1" ]; then
        LogError "No search parameter supplied"
      else
        StartNewSearch "$1"
        AddSearchTerms "$@"
      fi ;;
    u)              # Get URLs
      if [[ "$(ConfigGet_MEDIA_MAP)" ]]; then
        [[ $displayURLs == 0 ]] && displayURLs=1 || displayURLs=0
        SetRefreshResultsFlag
      else
        LogError "Cannot display URLs because (ConfigGet_MEDIA_MAP) is not set in $(MediaConfigFile)!"
      fi ;;      
    x)
      DoVariableAssignment "$@" && SetRefreshResultsFlag ;;
    "")
      DisplayPromptHelp ;;
    *)
      LogError "Invalid action: $action"
      DisplayPromptHelp ;;
  esac
}

ShowMenu() {
  declare FNAME="ShowMenu()"
  menuMode=1

  local cmd
  EditorLine cmd "Enter a command, or h for help, or q to quit: "

  # Something is changing IFS to $'\n', but I can't figure out where it is
  ResetIFS  

  local -l action=${cmd::1} 
  LogDebug "$FNAME.action = ${action:-<not set>}"

  local -a indices
  eval indices=(${cmd:2})       # Don't fuck with this again!

  LogDebug "$FNAME.#indices = ${#indices[@]}"
  LogDebug "$FNAME.indices() = $(SerializeArray -d=, -dS indices)"

  case "$action" in
    a | c | d | e | f | l | n | o | p | r | s | u | x)
      DoCommand "$action" "${indices[@]}" ;;
    q)
      LogVerbose "--- Quitting..."
      quit=1 ;;
    "")
      ;;
    h | help)
      DisplayPromptHelp ;;
    *)
      LogError "$(ColorText RED "Error: Invalid action: $action")"
      DisplayPromptHelp ;;
  esac
}

StartNewSearch() {
  LogDebug "Search term = $1"
  SEARCHTERMS=("$1")          # Create new set using supplied term
  SetRefreshResultsFlag       # Invalidate the current result set
}

AddSearchTerm() {
  LogDebug "Search term = $1"
  if [[ ! "${SEARCHTERMS[@]}" =~ "$1" ]]; then
    SEARCHTERMS+=("$1")
  fi
  SetRefreshResultsFlag       
}

AddSearchTerms() {
  for st in "$@"; do
    AddSearchTerm "$st"      # Add any additional terms 
  done
}

SetRefreshResultsFlag() {
  LogDebug "Invalidating current result set"
  refreshResults=1
  displayResults=1
}

# Command: c
Configure() {
  Run drbashctl "$@"
}

# Normalize filename
# TODO: Run media-fixtitle and media-fixtags only on the requested file.
#   Modify those scripts to recognize a file being passed in as opposed to a directory.
# Show the user the new filename.
# Then rerun their query (which might not contain the normalized file anymore).
Normalize() {
  [[ -z "$1" ]] && return 99
  CanRun process-media || { LogError "Dr. Bash is not installed correctly. Try uninstall/reinstall."; return 98; }

  local -n _victims="$1"      # filenames(string) : array
  process-media $(printf "%q " "${_victims[@]}")
}

# "Secret" admin command: x
DoVariableAssignment()
{
  local _varname="$1"
  local _newvalue="$2"
    
  if [[ -z "$_varname" ]]; then     # Print all variables
    declare -p
  else
    local -n _varvalue="$1"
    if [[ -z "$_newvalue" ]]; then  # Print variable value
      declare -p "$_varname"
      # printf "%s=%s\n" "$1" "$_var"
    elif [[ -z "$3" ]]; then        # Value assignment
      _varvalue="$_newvalue"
      declare -p "$_varname"
      return 0
    else                            # Array assignment
      shift
      _var=("$@")
      declare -p "$_varname"
      return 0
    fi
  fi
  return 1  # Not really a failure, just don't need to refresh results
}

# Commands: p & q
# Args:
#   $1 = name of indexed array of filenames
#   $2 = int: 1 = print only sets; 0 = print all items
GetFileProps() {
   [[ -z "$1" ]] && return 99

  local -n _filenames="$1"    # filename(string) : array       
  local -i _dupesonly=${2:-0} # dupesonly(bool) : integer
  local -a _props=()          # duration(integer)~properties(string) : array
  local _report=""            # props_report : string

  # Validate parameters
  case "$_dupesonly" in 0|1) ;; *) return 99 ;; esac

  for (( i=0; i < ${#_filenames[@]}; i++ )); do
    local file="${_filenames[$i]}"
    local compact=0
    ConfigGet_MEDIA_COMPACT && compact=1

    LogDebug "Calling: mediainfo $file"
    local _info="$(mediainfo "$file")"
    if [[ "$?" == 0 ]] && [[ -n "$_info" ]]; then
      local vInfo="$(DisplayMediaProperties "$_info" $compact $i)\n"
      LogDebug "vInfo(1) = $vInfo"

      # Extract duration from vInfo as a scalar value
      local duration="$(echo "$_info" | grep "Duration" | head -n1 | cut -d: -f2)"
      duration="$(printf "%s" "$duration" | awk '{ if ($2 == "h") $1=($1*3600)+($3*60); else $1=$1*60+$3; print $1 }')"
      LogDebug "duration(1) = $duration"

      # Add a composite value of [duration]~[vInfo] to the _props array
      b64_vInfo=$(printf '%s' "$vInfo" | b64_enc)
      _props+=("$(printf "%s~%s" "$duration" "$b64_vInfo")")
    else
      LogError "Failed to get media info for: $file"
    fi
  done
  unset i compact file _info vInfo duration

  LogDebug "$(declare -p _props)"

  # Build an indexable list of available color names from COLOR[]
  local -a colors=()
  local cname
  for cname in "${!COLOR[@]}"; do colors+=("$cname"); done

  local colorIndex=0
  local -a group_recs=()
  local prev_duration=''
  local line duration vInfo

  # Flush current group according to _dupesonly
  flush_group() {
    local size=${#group_recs[@]}
    if (( _dupesonly == 1 && size < 2 )); then
      group_recs=()   # discard singletons when sets-only
      ((colorIndex++))
      return
    else
      local setColor=${colors[$(( colorIndex % ${#colors[@]} ))]}
      local rec b64_vInfo vInfo
      for rec in "${group_recs[@]}"; do
        b64_vInfo=${rec#*~}
        vInfo="$(printf '%s' "$b64_vInfo" | b64_dec)"
        LogColor "$setColor" "$vInfo"
      done
      ((colorIndex++))
      group_recs=()
    fi
  }

  local -i idx=0
  while IFS= read -r -d '' rec; do
    duration=${rec%%~*}   # before first '~'
    LogDebug "duration(2) = $duration"

    if [[ -n $prev_duration ]] && (( duration - prev_duration > 2 )); then
      flush_group
    fi

    group_recs+=($rec)
    prev_duration=$duration
  done < <(printf '%s\0' "${_props[@]}" | sort -z -t'~' -k1,1n)

  flush_group
}


# Command: P
GetFileProps_old() {
  [[ -z "$1" ]] && return 99

  local -n _filenames="$1"    # filename(string) : array       
  local -i _dupesonly=${2:-0} # dupesonly(bool) : integer
  local -a _props=()          # duration(integer)~properties(string) : array
  local _report=""            # props_report : string

  for (( i=0; i < ${#_filenames[@]}; i++ )); do
    local file="${_filenames[$i]}"
    local compact=0
    ConfigGet_MEDIA_COMPACT && compact=1

    LogDebug "Calling: mediainfo $file"
    local _info="$(mediainfo "$file")"
    if [[ "$?" == 0 ]] && [[ -n "$_info" ]]; then
      local vInfo="$(DisplayMediaProperties "$_info" $compact $index)"
      
      # Extract duration from vInfo as a scalar value
      local duration="$(echo "$_info" | grep "Duration" | head -n1 | cut -d: -f2)"
      duration="$(printf "%s" "$duration" | awk '{ if ($2 == "h") $1=($1*3600)+($3*60); else $1=$1*60+$3; print $1 }')"
      # Add a composite value of [duration]~[index] to the _durations array
      _props+=("$(printf "%s~%s" "$duration" "$vInfo")")
    else
      LogError "Failed to get media info for: $file"
    fi
  done
  unset i compact file _info vInfo duration

  LogDebug "$(declare -p _props)"

  if [[ ${#_filenames[@]} == ${#videos[@]} ]]; then
    # When all results are selected, sort by runtime and paginate
    LogVerbose "Displaying properties of all results sorted by duration:"

    LogDebug "(Pre-Sort) $(declare -p _durations)"
    SortIntArray _durations
    LogDebug "(Post-Sort) $(declare -p _durations)"

    local -a colors=()
    for c in "${!COLOR[@]}"; do
      colors+=("$c")
    done

    local -i colorIndex=1 prevDuration=0
    local -a displayNames=()

    for d_i in "${_durations[@]}"; do
      local -i d=$(echo "$d_i" | cut -d- -f1)
      local -i i=$(echo "$d_i" | cut -d- -f2)
      LogDebug "d=$d | i=$i"

      local -i delta=$(( d - prevDuration ))
      if (( $delta > 2 )); then
        colorIndex=$(( colorIndex + 1 % ${#colors[@]} ))
        displayNames[-1]="${_props[$i]}"
      else
        [[ "${displayNames[-1]}" != "${_props[$i-1]}" ]] && displayNames+="${_props[$i-1]}"
        displayNames+="${_props[$1]}"
      fi

      LogDebug "ColorIndex=$colorIndex | Color=${colors[$colorIndex]}"
      prevDuration=d
    done 

    for n in displayNames; do
      LogDebug "Calling LogColor ${colors[$colorIndex]} \"$n\""
      LogColor ${colors[$colorIndex]} "$n"
    done| more
    LogColor NC       # Fix for color carryover bug in more
  else
    LogVerbose "Displaying properties of the specified results only."
    for p in "${_props[@]}"; do
      printf "%b\n\n" "$p"
    done | more
  fi
}

# Command: u
GetURL() {
  local mediaFile="$1"
  local -a driveMap

  [[ "$mediaFile" ]] || return 99
  [[ "$(ConfigGet_MEDIA_MAP)" ]] || return 30  # e.g. Z=/movies
  
  Split driveMap = "$(ConfigGet_MEDIA_MAP)"  
  [[ ${#driveMap[@]} == 2 ]] || return 30

  if [[ "$mediaFile" =~ ^${driveMap[0]} ]]; then
    printf "%s" "$(echo "$mediaFile" | sed -E "s|^${driveMap[0]}|${driveMap[1]::1}:|")"
  else
    printf "%b" "Error: Configured media file mapping cannot resolve media file path"
  fi
}

# Command: d
DoDeleteCommand() {
  local -n _filenames="$1"
  local -i retVal=1

  for file in "${_filenames[@]}"; do
    Log -n "Are you sure that you want to delete \"$(FormatFilename "$file")\" (this action might be irreversible) (Y/n)? "
    read -n1 choice
    if [ "${choice,,}" != 'n' ]; then 
      retVal=0
      local trash=0
      if [ "$(type -P trashcan)" ]; then
        trash=1
        Run $runParam trashcan "$file"
      elif [ "$(type -P trash)" ]; then
        trash=1
        Run $runParam trash "$file"
      fi
    
      # If it's still there, bypass trash and just get it gone! 
      if [ -f "$file" ]; then
        [ "$trash" == 1 ] && LogError "$(ColorText YELLOW "Moving $(FormatFilename "$file") to trash failed. Attempting permanent deletion...")"
        Run $runParam /bin/rm "$file"
      fi
    
      if [ -f "$file" ]; then
        LogError "$(ColorText YELLOW "All attempts to delete $(FormatFilename "$file") have failed!")"
      else
        Log "$(ColorText LGREEN "$(FormatFilename "$file") deleted\n")"
      fi
      unset trash
    fi
  done

  return $retVal # 0 if deletes happened, 1 if all deletes were declined
}

# Command: l
DoPlaylistCommand() {
 if [[ "$1" == '?' ]]; then
    PlaylistHelp
    return 0
  elif [ "$1" ]; then
    PLAYLIST_TITLE="$1"
  else
    PLAYLIST_TITLE="$(SerializeArray -d=- 'SEARCHTERMS')"
  fi

  # Sanity check
  if [ -z "$PLAYLIST_TITLE" ]; then
    LogError 'Playlist title could not be inferred.'
    return 2
  fi

  PLAYLIST_FILE="$(ConfigGet_MEDIA_PLAYLISTS)/$PLAYLIST_TITLE.m3u8"

  LogVerbose "Playlist Title = $PLAYLIST_TITLE"
  LogVerbose "Playlist File = $PLAYLIST_FILE"

  local drivemap="$2"
  [ -z "$drivemap" ] && drivemap="$(ConfigGet_MEDIA_MAP)"

  if [ "$drivemap" ]; then
    LogVerbose "Drive Mapping = $drivemap"

    declare -A map
    declare -a mapBits

    # $2 = "path=(drive letter | UNC path | URL prefix)"
    #   which is the opposite order they are added in the map structure
    Split mapBits '=' "$drivemap"
    if [ ${#mapBits[@]} == 2 ]; then
      if [[ "$(ConfigGet_MEDIA_MAP)" != "$drivemap" ]]; then 
        ConfigSet_MEDIA_MAP "$drivemap"
        Log "Drive mapping saved for this session."
      fi

      # Input format is: Linux Path -> Drive Letter
      # Opposite to the the way the user enters it here
      map+=(["${mapBits[0]}"]="${mapBits[1]}")
      CreatePlaylist 'videos' 'map' && Log  -l "Playlist created: $PLAYLIST_WINFILE" 
    else
      LogError "Playlist drive mapping specified improperly.\n"
      LogVerbose "#mapBits=${#mapBits[@]}"
      LogVerbose "mapBits=${mapBits[@]}"
      DisplayPromptHelp
      return
    fi
  else
    # Attempt to create playlist using drive mapping config in Samba
    CreatePlaylist 'videos' && Log -l "Playlist created: $PLAYLIST_WINFILE" 
  fi
}

# Parse the command line
ParseCLI() {
  LogDebug "ParseCLI parameters: $@"

  if HasSudo; then
    runParam='-r'
    Log "$(ColorText GREEN "Running with elevated privileges")"
  fi

  declare -g SEARCHTERMS=
  
  shopt -s extglob
  
  for p in "$@"; do
    case "$p" in
      -h)
        PrintHelp
        exit 0 ;;
      -f)
        DISPLAY_FULL_PATH=1 ;; 
      -F)
        DISPLAY_FULL_PATH=0 ;;
      -i)
        interactive=1 ;;
      -I)
        interactive=0 ;;
      -s)
        searchSubs=1 ;;
      -S)
        searchSubs=0 ;;
      -d*)
        MEDIA_ROOT="${p#*=}" ;;
      $(LogParamsCase) ) ;;
      -*)
        Log "Warning: Invalid parameter: $p" ;;
      *)
        if [[ -z "${SEARCHTERMS[@]}" ]]; then
          StartNewSearch "$p"
        else
          AddSearchTerm "$p"
        fi ;;
    esac
  done
 
  if [[ -n "${SEARCHTERMS[0]}" ]]; then
    _shellParams="$(printf "%q" "${SEARCHTERMS[@]}")"
    PushHistory "s $_shellParams"
  fi

  if ConfigGet_MEDIA_REPOSEARCH && [ -d "$(ConfigGet_MEDIA_REPO)" ] && [ "$MEDIA_ROOT" == '.' ]; then
    MEDIA_ROOT="$(ConfigGet_MEDIA_REPO)"
  elif [ "$MEDIA_ROOT" == '.' ]; then
    MEDIA_ROOT="$PWD"
  fi

  # Put the trailing slash right back on so that find's bitch ass will work correctly
  [ "${MEDIA_ROOT: -1}" == '/' ] || MEDIA_ROOT+=/

  # Call it a recap or call it a warning...
  [ "$searchSubs" == 1 ] && local r='recursively'
  Log "Searching ${r} in: $MEDIA_ROOT"

  # Disable interactive mode if our output is being piped to another command.
  if IsInteractive; then 
    LogVerbose "Disabling interactive mode because either stdout has been redirected or we've been invoked in a non-login context."
    interactive=0
  fi

  # Now make $interactive read-only
  declare -r interactive
  
  LogVerbose "Search Terms (ParseCLI) = $(SerializeArray -q -d=, -dS SEARCHTERMS)"
}

InteractiveLoop() {
  while [[ $quit == 0 ]]; do
    if [[ $displayResults == 1 ]]; then
      DisplayResults || exit $?
    fi

    if [[ $showMenu == 1 ]] && [[ $quit == 0 ]]; then
      ShowMenu
    fi
  done
}

# Initializes the command history buffer
InitHistory

ParseCLI "$@"

if [[ $interactive == 0 ]]; then
  DisplayResults
else
  InteractiveLoop
fi
