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
  \te\tEdit all dem sumbitches!
  \te #...\tEdit the name of one or more files.
  \tf PATTERN\tFilter the current results to only those also matching PATTERN.
  \t\t(It's the same behavior as if you had specified an additional term in the original query.)
  \tl\tCreate a Windows Media Player compatible playlist (.m3u8) from your search results.
  \t\tThe playlist title will be your search query and it will fail if you have no configured share mapping.
  \tl TITLE\tCreate a playlist from your search results named TITLE.
  \t\tPlaylist creation will fail if you haven't already configured at least one drive mapping.
  \tl TITLE PATH=DRIVE_LETTER|UNC|URL\tCreate a playlist from your search results named TITLE using the specified drive mapping.
  \tl ?\tGet more help using the playlist feature.
  \tn\tApply file normalization rules (set via action 'a') to all files in result set.
  \tn #...\tApply file normalization rules to the specified files.
  \t\tIf you want to apply the rules to a set of files in a staging area and merge them into your main repo,
  \t\t  exit this program and run: mediamerge
  \to\tSame as 'p' but only show the files grouped by runtime
  \tp\tShow media properties for all search results ordered and color-grouped by runtime.
  \tp #...\tGet media properties. Specify one or more file indices (e.g. p 1 2 3). Results in the order you specified, no color.
  \tr\tRefresh/Redisplay the list of matches.
  \ts PATTERN\tInitiate a new title search using PATTERN.
  \tu\tToggle between file and URL style output.
  \tu [PATH=DRIVE_LETTER|UNC|URL]\tSet a path mapping (equates a path on the server with something you can access from a client) 
  \tw\tReset permissions for all files in search directory"
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

# Applies the values in the SEARCHTERMS array and returns the matching set of files in the MEDIA_ROOT.
# + $1 = Name of the variable used to hold the resulting array of filenames
SearchFiles() {
  local -n results="$1"

  local searchTerm="${SEARCHTERMS[0]}"
  if [[ -n "$searchTerm" ]]; then
    LogVerbose "Searching for: \"$searchTerm\""

    searchTerm="$(FormatRegex "$searchTerm")"

    if (( oldSearch )); then
      if (( $searchSubs )); then
        IFS=$'\n' results="$(find "$MEDIA_ROOT" -type f -regextype egrep -iregex "$searchTerm" 2>/dev/null)"
      else
        IFS=$'\n' results="$(find "$MEDIA_ROOT" -maxdepth 1 -type f -regextype egrep -iregex "$searchTerm" 2>/dev/null)"
      fi
    else
      if (( $searchSubs )); then
        IFS=$'\n' videos=($(find "${MEDIA_ROOT}" -type f | grep -Ei "^.*/[^/]*${searchTerm}[^/]*$"))
      else
        IFS=$'\n' videos=($(find "${MEDIA_ROOT}" -maxdepth 1 -type f | grep -Ei "^.*/[^/]*${searchTerm}[^/]*$"))
      fi
    fi

    SortArray "results"
  fi
}

FilterMatches() {
  if [[ ${#SEARCHTERMS[@]} < 2 ]]; then
    LogDebug "No filter criteria specified."
    return
  fi

  local -n results="$1"
  local -a results_temp=()
  
  local -a filterTerms=("${SEARCHTERMS[@]}")
  unset 'filterTerms[0]'
  
  LogVerbose "Filtering results on: ${filterTerms[*]}"
  
  for searchResult in "${results[@]}"; do
    base="${searchResult##*/}"
    dir="${searchResult%/*}"
    lc_base="${base,,}"
  
    matched=0
    for term in "${filterTerms[@]}"; do
      [[ -z $term ]] && continue
      lc_term="${term,,}"
      if [[ "$lc_base" == *"$lc_term"* ]]; then
        matched=1
        break
      fi
    done
  
    (( matched )) && results_temp+=("$dir/$base")
  done
  
  results=("${results_temp[@]}")

  if [ ${#results[@]} == 0 ]; then
    LogVerboseError "It looks like we filtered out all of the results!"
    results=()
    showMenu=0
    return 1
  else
    Log "Performed incremental filter and am left with ${#results[@]} matches."
  fi
}

DisplayResults() {
  displayResults=0

  if [[ $refreshResults == 1 ]]; then
    videos=()
    LogVerbose "Search Terms (DisplayResults) = $(SerializeArray -q -d=, -dS SEARCHTERMS)"
    SearchFiles 'videos'
    LogDebug "SearchFiles() returned ${#videos[@]} results."
    FilterMatches 'videos'
    LogDebug "FilterMatches() returned ${#videos[@]} results."
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
  ResetIFS

  local -l action="$1"; shift 
  local -a result_indices=("$@")
  local -a filenames=()

  [ -z "$action" ] && return

  case "$action" in
    e | o | p | d)
      # Convenience mode
      if [[ 0 == "${#result_indices[@]}" ]]; then
        local -i q=$(( ${#videos[@]} - 1 ))
        result_indices=($(seq 0 $q))
      fi

      # Get the filenames corresponding to the indices passed in
      LogDebug "Number of items in videos[] = ${#videos[@]}"
      for i in ${result_indices[@]}; do
        filenames+=("${videos[$i]}")
      done ;;
  esac

  if LogDebugEnabled; then
    LogDebug "action = $action"
    LogDebug "filenames = $(SerializeArray -de filenames)"
  fi

  case "$action" in
    a)              # Archive
      local path="${1:-$DRB_MEDIA_REPO/${SEARCHTERMS[@]}}"
      Run $runParam mkdir -p "$path"
      # TODO: Implement a progress meter
#      Log "Archiving [          ]"; 
      for v in "${videos[@]}"; do
        Run $runParam cp -a "$v" "$path/"
      done
      Log "Search results have been archived to $path"
      unset v path ;;
    c)              # Configure
      Configure "$@" ;;
    d)              # Delete
      for filename in "${filenames[@]}"; do
        if DeleteFile "$filename"; then
          SetRefreshResultsFlag
        fi 
      done ;;
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
      GetFileProps 'result_indices' 'filenames' 1 0 ;;
    p)              # Properties
      GetFileProps 'result_indices' 'filenames' 0 0 ;;
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
        LogError "Cannot display URLs because DRB_MEDIA_MAP is not set.
        Set it with the command: c media DRB_MEDIA_MAP <serverpath>=<URL>"
      fi ;;      
    w)
      ResetFilePerms ;;
    x)
      DoVariableAssignment "$@" 
      [[ "$1" == 'DEBUG' ]] && { DoVariableAssignment 'VERBOSE' $2; } ;;
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
    a | c | d | e | f | l | n | o | p | r | s | u | w | x)
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
  LogDebug "Adding search term = $1"
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
  LogDebug "Setting refresh results flag"
  refreshResults=1
  displayResults=1
}

# Command: c
Configure() {
  Run drbashctl "$@"
}

# Command: w
ResetFilePerms() {
  if ! CanSudo; then
    LogError "Resetting file permissions requires sudo access!"
    return 1
  fi

  local -l user="$(ConfigGet_MEDIA_USER)"
  local -l group="$(ConfigGet_MEDIA_GROUP)"
  [[ -z "$user" ]] && { LogError "No media user configured."; return 2; }
  [[ -z "$group" ]] && { LogError "No media group configured."; return 3; }


  local file="$1"
  if [[ -n "$file" ]]; then
    # Make sure that this file really exists first
    [[ -f $file ]] || { LogError "File $file does not exist!"; return 4; }
    local dir="$(dirname "$file")"
    # Directories
    sudo -E chown $user:$group "$dir"
    sudo -E chmod 777 "$dir"
    # Files
    sudo -E chown $user:$group "$file"
    sudo -E chmod 664 "$file"
  else
    Log -n "Are you sure you want to set all directories and files within $MEDIA_ROOT to:
    User: $user
    Group: $group
    Directories: rwxrwxrwx
    Files: rw-rw-r--

    Confirm [Y/n]? "
    read -n1 choice; echo
    [[ ${choice,,} == n ]] && return 9

    # Directories
    find "$MEDIA_ROOT/" -type d -exec sudo -E chown $user:$group "{}" +
    find "$MEDIA_ROOT/" -type d -exec sudo -E chmod 777 "{}" +
    # Files
    find "$MEDIA_ROOT/" -type f -exec sudo -E chown $user:$group "{}" +
    find "$MEDIA_ROOT/" -type f -exec sudo -E chmod 664 "{}" +
  fi
}

# Normalize filename
# Run media-fixtitle and media-fixtags only on the requested files.
# Then rerun their query (which might not contain the normalized files anymore).
Normalize() {
  [[ -z "$1" ]] && return 99
  if ! CanRun media-fixtitle || ! CanRun media-fixtags; then
    LogError "Dr. Bash is not installed correctly. Try uninstall/reinstall."
    return 98
  fi

  local -n _victims="$1"      # filenames(string) : array
  media-fixtitle $(printf "%q " "${_victims[@]}")
}

# "Secret" admin command: x
DoVariableAssignment()
{
  local _varname="$1"
  if [[ -z "$_varname" ]]; then     # Print all variables
    declare -p
    return
  fi

  local -n _varvalue="$1"
  local _newvalue="$2"
    
  if [[ -n "$_newvalue" ]]; then  # Print variable value
    if [[ -z "$3" ]]; then        # Value assignment
      _varvalue="$_newvalue"
    else                            # Array assignment
      shift
      _varvalue=("$@")
    fi
  fi
  declare -p "$_varname"
}

# Commands: o & p
# Displays the properties (size, duration, resolution) of the specified media files.
# Files will be sorted in ascending order according to duration.
# Files will be grouped if their durations are less than 2 seconds apart.
# Files that have identical duration will be displayed in italics.
# Files that have identical duration and size will be displayed in underline.
#
# The output format of this command is controlled by the DRB_MEDIA_COMPACT boolean environment variable
# True:
#     ##) <title> [<tags>].mp4
#         <size> | <duration: X hr YY min ZZ s> | <resolution: WWWW x HHHH>
# False:
#     ##) <title> [<tags>].mp4
#         Size:     <size: XXX MB>
#         Duration: <duration: X hr YY min ZZ s>
#         Height:   <height: HHHH pixels>
#         Width:    <width: WWWW pixels>
#
# Args:
#   $1 = name of indexed array of indices (either to entire result set or a subset)
#   $2 = name of indexed array of filenames
#   $3 = int: 1 = print only sets; 0 = print all items
#   $4 = int: grouping duration tolerance [default: 2 sec]
#
# Notice: Be VERY careful when making any changes to this function.
# It is extremely complex and algorithmically state-machine-based.
# The function-within-a-function should be your first clue that you're not in Kansas anymore!
#
# Here's the part that's breaking your brain:
# _props[] = duration~size~Base64(properties_display)
# group_props[] = style~Base64(properties_display)
# Why are the properties Base64-encoded? That'll be a good subject for your PhD dissertation!
GetFileProps() {
  [[ -z "$1" ]] && return 99

  ResetIFS

  local -n _indices="$1"              # int : array
  local -n _filenames="$2"            # string : array       
  local -i _dupesonly=${3:-0}         # bool : integer
  local -i groupingTolerance=${4:-2}  # seconds : integer
  local -a _props=()                  # duration(integer)~properties(string) : array

  # Validate parameters
  case "$_dupesonly" in 0|1) ;; *) _dupesonly=0 ;; esac

  {
    if [[ $_dupesonly == 1 ]]; then
      [[ ${#_filenames[@]} == 1 ]] && { LogError "Cannot show pairs of results with only one result!"; return 0; }
      [[ ${#_filenames[@]} == 0 ]] && { LogError "Cannot show pairs of results when you have no results!"; return 0; }
    fi

    (( ${#filenames[@]} > 50 )) && Log "Please wait..."

    for (( i=0; i < ${#_filenames[@]}; i++ )); do
      local file="${_filenames[$i]}"
      local compact=0
      ConfigGet_MEDIA_COMPACT && compact=1
  
      LogDebug "Calling: mediainfo $file"
      local _info="$(mediainfo "$file")"

      if [[ "$?" == 0 ]] && [[ -n "$_info" ]]; then
  
        # Extract duration from vInfo as a scalar value
        local size="$(echo "$_info" | grep 'File size' | cut -d: -f2 | Trim --)"
        local duration="$(echo "$_info" | grep "Duration" | head -n1 | cut -d: -f2)"
        duration="$(printf "%s" "$duration" | awk '{ if ($2 == "h") $1=($1*3600)+($3*60); else $1=$1*60+$3; print $1 }')"
        LogDebug "size = $size"
        LogDebug "duration = $duration"
  
        local vInfo="$(DisplayMediaProperties "$_info" $compact ${_indices[$i]})\n"
        LogDebug "vInfo = $vInfo"
        
        # Add a composite value of [duration]~[size]~[vInfo] to the _props array
        local b64_vInfo=$(printf '%s' "$vInfo" | b64_enc)
        _props+=("$(printf "%d~%s~%s" "$duration" "$size" "$b64_vInfo")")   # _props=duration~size~base64(vInfo)
      else
        LogError "Failed to get media info for: $file"
      fi
    done
  }

  LogDebugEnabled && LogDebug "$(declare -p _props)"

  local colorIndex=0
  local -a group_props=()

  # A group can be any set of one or more results
  # Show them all unless the _dupesonly flag was passed in
  flush_group() {
    local size=${#group_props[@]}
    
    if (( _dupesonly == 0 || size > 1 )); then
      local IFS=
      local -i color=$(( (colorIndex++ % 7) + 31 ))
      local -i style 
      local prop b64_vInfo vInfo line
      local -a propArray=()

      # local -i iteration=0
      for prop in "${group_props[@]}"; do
        Split 'propArray' '~' "$prop"
        style="${propArray[0]}"
        b64_vInfo="${propArray[1]}"
        vInfo="$(printf '%s' "$b64_vInfo" | b64_dec)"
        LogColorCSB -n $color $style 0 "$vInfo"
        # Only apply the font style to the file name
        #styleLine=1;
        #while IFS= read -r -d '' line; do
        #  (( styleline )) \
        #    && LogColorCSB $color $style '' "$line" \
        #    || LogColorCSB $color '' '' "$line"
        #  styleLine=0
        #done < <(printf '%s' "$vInfo")
      done
      Log
    fi
    group_props=()
  }

  local prev_duration=0 prev_size=0 
  local duration b64_vInfo prop size
  local -i style=0
  local -a propArray

  # Go through the properties and figure out what style they should be rendered in
  #   then store that information into a group collection.
  while IFS= read -r -d '' prop; do
    Split 'propArray' '~' "$prop"

    duration="${propArray[0]}"
    size="${propArray[1]}"
    b64_vInfo="${propArray[2]}"

    style=0
    if (( duration - prev_duration > $groupingTolerance )); then
      flush_group
    elif (( duration == prev_duration )); then
      style=4                               # italics
      [[ size == prev_size ]] && style=5    # underline
    fi

    group_props+=("$(printf "%d~%s" "$style" "$b64_vInfo")") 
    prev_duration="$duration"
    prev_size="$size"
  done < <(printf '%s\0' "${_props[@]}" | sort -z -t'~' -k1,1n)

  flush_group
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
DeleteFile() {
  local file="$1"
  local -i prompt=${2:-1}
  local -i retVal=1

  # Check that file exists and we have sufficient permission to delete it
  if [[ ! -f "$file" ]]; then
    LogError "$file does not exist!"
    return 1
  elif [[ $runParam == -u ]] && [[ ! -w "$(dirname "$file")" ]]; then
    LogError "Unsufficient permissions to delete $file"
    return 2
  fi

  if [[ $prompt == 1 ]]; then
    Log -n "Are you sure that you want to delete \"$(FormatFilename "$file")\" (this action might be irreversible) (Y/n)? "
    read -n1 choice
  else
    choice='y'
  fi

  [[ "${choice,,}" == 'n' ]] && return 2

  TryDeleteFile() {
    local cmd="$1"
    local file="$2"

    [[ -z "$cmd" || -z "$file" ]] && return 1

    if ! Run -u "$cmd" "$file" 2>/dev/null; then
      Run -r "$cmd" "$file" 2>/dev/null
    fi

    [[ -f "$file" ]] && return 1 || return 0
  }

  CanSudo && ResetFilePerms "$file"
  local trash=0
  if CanRun trashcan; then
    trash=1
    TryDeleteFile trashcan "$file"
  elif CanRun trash; then
    trash=1
    TryDeleteFile trash "$file"
  fi

  # If it's still there, bypass trash and just get it gone! 
  if [ -f "$file" ]; then
    [ "$trash" == 1 ] \
      && LogColor LYELLOW "Moving $(FormatFilename "$file") to trash failed. Attempting permanent deletion..." \
      || Log "No trash configured. Deleting $(FormatFilename "$file") permanently..."
    TryDeleteFile /bin/rm "$file"
  fi

  if [ -f "$file" ]; then
    LogColor RED "All attempts to delete $(FormatFilename "$file") have failed!"
    return 1
  else
    LogColor LGREEN "$(FormatFilename "$file") deleted"
    return 0
  fi
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
