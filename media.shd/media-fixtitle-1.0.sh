#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
USERDATA=${USERDATA:-$USERSRC}

# Do not rely on $0 for multiple reasons:
# 1. It doesn't exist in all cases (just trust me on this one)
# 2. It may reflect the name of symlinks to the command which may differ from what is intended or desired.
# 3. If the file is sourced $0 will be the function name.
declare -r APPNAME="media-fixtitle"
declare -r FILE_ABBR="${USERDATA:-.}/$APPNAME-abbr.shdata"
declare -r FILE_FILLER="${USERDATA:-.}/$APPNAME-filler.shdata"
declare -r FILE_PATTERNS="${USERDATA:-.}/$APPNAME-patterns.shdata"
declare -r FILE_DELETE="${USERDATA:-.}/$APPNAME-delete.shdata"

PrintHelp () {
  tabs 4
  Log
  Log "Normalizes and removes the specified text or extended regular expression match(es) from the title of all media files in the current directory.
  This tool does not recurse through subdirectories.
  This tool is intended to be one step in a pipeline of automated media file processing."
  Log
  Log "$(Header "Concept:") This utility is only intended to operate on media files named according to the following convention:"
  Log "\t<title> [<tags>].<ext>
  \tWhere:
  \t\t<tags> = Whatever you define"
  Log "Example: 12 Angry Men [classic.movie 2.rank court.drama bob.favorite 720p].mp4"
  Log
  Log "$(Header "Usage:") $APPNAME [OPTIONS...] [EXPR...]"
  Log
  Log "$(Header "OPTIONS")\t(optional; do not combine)"
  LogTable "\t-h\tDisplay this help text.
  \t-v\tVerbose output.
  \t-vv\tEquivalent to -s.
  \t-s\tSimulate what would be done in a real run (implies -v).
  \t-st\tDeveloper testing mode.
  \t-fs\tForce short run (since .lastrun file modification date).
  \t-fl\tForce long run (ignore .lastrun file)."
  Log
  Log "$(Header "EXPR")\t(optional)"
  Log "\tThe case-insensitive literal text and/or extended regular expression(s) to remove.
  \tSingle-quote each expression with a space in between them.
  \tDon't forget to escape regex control characters (e.g. '\[').
  \tUse 'sed -E' to develop your expressions.
  \tAny expressions specified will be applied in addition to the default set."
  Log
  LogHeader "Filename Normalization:"
  LogTable "\t* Replaces '-' in titles with space if title contains no natural spaces.
  \t* Replaces all occurances of '+' and '_' in the title with spaces.
  \t* Capitalizes the first letter of every word in the title.
  \t* Capitalizes certain common initialisms in the title.
  \t* Lower-cases certain common words in the title (e.g: a, or, the, etc).
  \t* Reduces multiple sequential space characters to just one space character.
  \t* Any text after the close bracket will be removed."
  Log
  LogHeader "Return Codes:"
  LogTable "\t0\tSuccess or user interactively terminated
  \t1\tInvalid command-line parameter supplied
  \t99\tCoding error; failed sanity check. File a bug report."
  Log
  Log "$(Header "Removal Expressions") (source: $FILE_PATTERNS):"
  if [ -r "$FILE_PATTERNS" ]; then
    readarray -t patterns < "$FILE_PATTERNS"
    Log "\t(Any text matching the following expresions will be removed from the title portion of the file name)"
    for p in "${patterns[@]}"; do
      Log "\t$(ColorText LRED "* $p")"
    done
    Log
    unset patterns
  else
    LogError "\t$(ColorText YELLOW ">> File does not exist or is not readable <<")"
  fi

  Log "$(Header "Abbreviations") (source: $FILE_ABBR):"
  if [ -r "$FILE_ABBR" ]; then
    readarray -t abbr < "$FILE_ABBR"
    Log "\t(To be capitalized exactly as shown)"
    Log "\t> $(ColorText LBLUE "${abbr[*]}")\n"
    unset abbr
  else
    LogError "\t$(ColorText YELLOW ">> File does not exist or is not readable <<")"
  fi
  
  Log "$(Header "Filler words") (source: $FILE_FILLER):"
  if [ -r "$FILE_FILLER" ]; then
    readarray -t filler < "$FILE_FILLER"
    Log "\t(These words will be set to lower-case)"
    Log "\t> $(ColorText LPURPLE "${filler[*]}")\n"
    unset filler
  else
    LogError "\t$(ColorText YELLOW ">> File does not exist or is not readable <<")"
  fi

  Log "$(ColorText RED "File Deletion:") (source: $FILE_DELETE):"
  Log "\tAt the end of the run, you will prompted to confirm whether you want to delete certain temporary or possibly duplicate files in the directory. 
  \tAll files matching any of these patterns will be marked for deletion:"
  if [ -r "$FILE_DELETE" ]; then
    readarray -t deletes < "$FILE_DELETE"
    for d in "${deletes[@]}"; do
      Log "\t$(ColorText RED "* $d")"
    done
    unset deletes
  else
    LogError "\t$(ColorText YELLOW ">> File does not exist or is not readable <<")"
  fi
  
  Log
  Log "Note: Set the USERDATA environment variable to the desired path of the preceding data files."
  Log
  Log "$(Header "Usage Examples:")"
  Log "\tTo force a long (all files) run with verbose logging, do:
  \t\t$(ColorText LGREEN "$APPNAME -v -fl")
  \tDo NOT:
  \t\t$(ColorText LRED "$APPNAME -vfl")
  \tRemove text matching pattern:
  \t\t$(ColorText LGREEN "$APPNAME \"DVD\"")"
  Log
}

# Applies static normalization rules to title
# +$1 = file name
# -newFilename = Normalized filename
# -deleteFile = Set if file is a duplicate (no false positives, many false negatives)
NormalizeTitle() {
  local file="$1"
  
  # Parse out the file extension
  IFS='.' fileParts=($file)
  local -l fileExt="${fileParts[-1]}"
  local filename="${file%.$fileExt}"
  
  # Check whether this file is marked as a duplicate or other junk
  for dPattern in "${deletePatterns[@]}"; do
    if [ "$(echo "$file" | grep -Ei "$dPattern")" ] || \
       [ "$(echo "$filename" | grep -Ei "$dPattern")" ]; then
           LogVerboseError "$(ColorText LRED "Flagging $file for deletion.")"
      deleteFiles+=("$file")
      return 1
    fi
  done

  # Separate the media name from the tags
  IFS='[' fileParts=($filename) 
  local title="${fileParts[0]}"
  local -l tags="$(echo "${fileParts[1]}" | sed 's/\].*//')"

  LogDebugError "\nFile  = $file"
  LogDebugError "Title = $title"
  LogDebugError "Tags  = $tags"
  LogDebugError "Ext   = $fileExt"

  if [ ${#fileParts[*]} -gt 2 ] || [ -z "$title" ]; then
    LogErrorTee "$(ColorText RED "ERROR: Invalid file name: $file")
    The only square braces permitted in file names are the ones around the tags.
    Manual intervention required to remove extra square braces!"
    return 1
  fi

  LogDebugError -n "a "

  # Perform the requested deletions
  local newTitle="$title"
  for pattern in "${trimPatterns[@]}"; do
    newTitle="$(echo "$newTitle" | sed -E "s/$pattern//ig")"
 #   if [ "$newTitle" == "$title" ] && [ "$(echo "$newTitle" | grep -i "$pattern")" ]; then
 #     LogDebugError "\n>>> $newTitle doesn't match $pattern!" \
 #     || LogDebugError "\nPattern hit: "$pattern"\nOld Title: "$title"\nNew Title: "$newTitle""
 #   fi
  done

  # Sanity check
  if [ -z "$newTitle" ]; then
    LogVerboseError "WARN: Requested deletions removed entire title. Undoing deletions and proceeding with normalization"
    newTitle="$title"
  fi

  # Force title to all lower-case
  newTitle="${newTitle,,}"

  LogDebugError -n "b "
  
  # Replace '-' in titles with space if title contains no natural spaces.
  IFS=" " testCut=($newTitle)
  if [ ${#testCut[@]} == 1 ]; then
    newTitle="$(echo "$newTitle" | sed 's/-/ /g')"
  fi
  unset testCut 

  LogDebugError -n "c "
  
  # Replace any + or _ chars with spaces & remove multiple spaces
  newTitle="$(echo "$newTitle" | sed -E 's/([+_]|\s+)/ /g' | sed -E 's/\s$//g')"

  LogDebugError -n "d " 
  
  # Capitalize the first letter of evey word
  #   For some obnoxious reason, \b thinks that apostrophes are not a part of words and underscores are!
  #   So the second sed statement is a fix for that bug.
  newTitle="$(echo "$newTitle" | sed -E 's/\b(.)/\u\1/g' | sed -E "s/'(.)/'\l\1/g")"

  LogDebugError -n "e "

  # Capitalize certain common initialisms
  for capital in ${ABBREVIATIONS[*]}; do
    newTitle="$(echo "$newTitle" | sed "s/\b$capital\b/$capital/ig")"
  done

  LogDebugError -n "f "
  
  # Enforce lower-case for certain words 
  for lower in ${FILLERWORDS[*]}; do
    newTitle="$(echo "$newTitle" | sed "s/\b$lower\b/$lower/ig")"
  done

  LogDebugError -n "g "

  # Capitalize the first word of every title
  newTitle="$(echo "$newTitle" | sed -E 's/^(.)/\u\1/')"

  LogDebugError -n "h "
  
  # Recombine media name and tags
  newFilename="${newTitle}"
  [ "$tags" ] && newFilename+=" [${tags}]"
  newFilename+=".${fileExt:-mp4}"
 
  # Remove any duplicated spaces that may have resulted from deletions
  newFilename="$(echo "$newFilename" | sed -E 's/\s+/ /g' | sed -E 's/(^\s+|\s+$)//g')"

  LogDebugError "i"
  
  echo -n "$newFilename"
  return 0
}

# Removes square braces that do not appear to be the ones enclosing tags.
# Ensures that open braces have corresponding close braces.
# Best effort; will not always guess correctly; use with caution!
# If the filename has 0 or 1 open brace and the same number of close braces,
#   this function will return your filename back to you unmodified.
# + $1 = The filename with extra square braces (no file extension!)
# - stdout = The filenanme with the extra braces replaced with parentheses
FixBraces() {
  local filename="$1"
  [ -z "$filename" ] && return

  local title="${filename%[*}"          # title = the string up to the last occurence of [
  if [ "$title" == "$filename" ]; then  # If there are no instances of [,
    echo "$filename"                    # Give them their filename back,
    return                              # and bail.
  fi

  local tmp="${title%[*}"                 # Get another substring up to the next last occurence of [
  local tmp2="${title:${#tmp}}"           # Put the remainder of the substring a second variable
  if (( ${#tmp} != ${#title} )); then     # If there are more instances of [,
    tmp="$(echo "$tmp" | sed 's/\[/(/g')" # Replace all remaining [s with (s
    tmp="$(echo "$tmp" | sed 's/\]/)/g')" # Replace all remaining ]s with )s
  fi

  # Ensure that there exists exactly one close brace
  local tags="${filename##*]}"
  tags="${tags: -1}]"

}

# Common capitalized initialisms used in media filenames
# Data files contain only one ewntry per line
# Abbreviations should be capitalized exactly how you want to see them (e.g TX for Texas)
readarray -t ABBREVIATIONS < "$FILE_ABBR"; declare -ra ABBREVIATIONS

# Filler words are words like: a, in, to, it
# If you prefer having every word capitalized, then don't include any filler words
readarray -t FILLERWORDS < "$FILE_FILLER"; declare -ra FILLERWORDS

# Trim patterns are extended regular expressions. All text matching any of these patters is removed from the title only (not tags)
# trimPatterns is not a read-only value because the user can supplement it via cli parameters.
readarray -t trimPatterns < "$FILE_PATTERNS"; declare -a trimPatterns 

# deletePatterns is a collection of regexes run (grep'd) on the full filename.
# Any filename that matches one of these patterns gets marked for deletion
readarray -t deletePatterns < "$FILE_DELETE"; declare -ra deletePatterns

# deleteFiles is a collection of the files marked for deletion.
# This way, we can do all of the renames first and then bug the user for 
#   confirmation of the deletions at the end 
#   so they have time to go grab a mug of coffee while the renames run
declare -a deleteFiles=()

# Parse command line args
for p in "$@"; do
  case "$p" in
    -h | --help | ?)
      PrintHelp; exit 0 ;;
    -st)
      LogEnableDebug
      testMode=1 ;;
    -s)
      LogEnableDebug ;;
    -fs)
      forceShortRun=1 ;;
    -fl)
      forceLongRun=1 ;;
    -v | -vv | -q)
      ;; # Handled by "parent class": logger.sh
    -*)
      LogError "ERROR: Option not recognized: $p"
      exit 1 ;;
    *)
      trimPatterns+=("$p") ;;
  esac
done

# You can't shut me up that easily!
if [ "$(LogQuietEnabled)" ]; then
  unset QUIET
  LogError "Quiet mode not supported!"
  exit 1
fi

# Reminder: "${arr[*]}"  <-- Serialization
#           "${arr[@]}"  <-- Iteration

LogDebug "Simulation Mode: No changes will be written to disk."
LogDebug "Abbreviations: ${ABBREVIATIONS[*]}"
LogDebug "Filler Words:  ${FILLERWORDS[*]}"

LogVerbose "Patterns to remove:"
for p in "${trimPatterns[@]}"; do
  LogVerbose "\t$p"
done
unset p

# Get the set of files to act on
declare -a fileSet
declare -r LastRunFileExt="lastrun" 
declare -r LastRunFile=".$APPNAME.$LastRunFileExt"

failReason="<unknown>"
successReason="<unknown>"
if [ $forceLongRun ]; then
  failReason="long run was forced by command-line parameter."
elif [ ! -e "$LastRunFile" ];then 
  failReason="$LastRunFile does not exist."
elif [ $forceShortRun ]; then
  successReason="short run was forced by command-line parameter."
  shortRun='y'
elif [ "$(cat $LastRunFile)" == "${trimPatterns[*]}" ]; then
  successReason="$LastRunFile exists and its contents match the current run parameters."
  shortRun='y'
else
  failReason="the requested text to remove does not match what was previously specified.\n"
  failTemp="Previous:\tCurrent:\n"
  IFS=$'\n' lrfPatterns=($(cat $LastRunFile))
  for (( i=0; i<${#trimPatterns[*]}; i++ )); do
    failTemp+="${lrfPatterns[$i]}\t${trimPatterns[$i]}\n"
  done
  failReason+="$(echo -e "$failTemp" | FormatTable)"
fi

if [ "$testMode" ]; then
  declare -r testFilePrefix='='
  
  IFS=$'\n'; fileSet=($(find . -maxdepth 1 -type f -name "$testFilePrefix*" | sed 's/^\.\///'))
  LogDebug "--- Running in Testing Mode ---"
  
  for tfile in "${fileSet[@]}"; do
    LogDebug "Found Test File: $tfile"
  done
elif [ $shortRun ]; then
  Log "Performing abbreviated run because $successReason"
  # The sed part removes the leading ./ from the filename
  IFS=$'\n'; fileSet=($(find . -maxdepth 1 -type f -newer "$LastRunFile" | sed 's/^\.\///'))
else
  LogError "Cannot perform abbreviated run because $failReason"
  IFS=$'\n'; fileSet=($(find . -maxdepth 1 -type f | sed 's/^\.\///'))
fi

LogVerbose "Found ${#fileSet[*]} files..."

if [ ${#fileSet[*]} -gt 100 ]; then
  Log "Target file count: ${#fileSet[*]}"
  Log -n "Are you sure you want to continue [Y/n] (10s)? " 
  read -n 1 -t 10 cont; echo
  [ "${cont,,}" == 'n' ] && exit 0
  unset cont
fi

declare -l doFileOp='y' prompt='y'
declare -i renameCount=0
declare -i deleteCount=0

#
# --- FILE LOOP ---
#
for (( fileIndex=0; fileIndex < ${#fileSet[@]}; fileIndex++ )) 
do
  declare filename="${fileSet[$fileIndex]}"

  # There are some files we need to ignore
  [ -e "$filename" ] || continue  # Hack around bash bugs
  [ ${#filename} -lt 5 ] && continue
  [[ "$filename" =~ .$LastRunFileExt$ ]] && continue;

  newFilename="$(NormalizeTitle "$filename")"
  [ $? == 0 ] || continue

  # Sanity check
  [ -z "$newFilename" ] && { LogError "Internal Error: NormalizeTitle() returned a null filename!"; exit 99; }

  LogDebug "Cur file name = $filename\nNew file name = $newFilename"

  if [ "$newFilename" != "$filename" ]; then
    declare -i progress=`awk -v fileIndex=$fileIndex -v numFiles=${#fileSet[@]} 'BEGIN { printf "%3d", (fileIndex/numFiles)*100 }'`
    declare fileOpText="Rename: ${filename}\n$progress%  => $(ColorText LPURPLE "$newFilename")"
    Log "$fileOpText"

    # Force doFileOp to 'n' if this is a simulation
    if [ "$(LogDebugEnabled)" ]; then
      prompt='n'
      doFileOp='n'
    fi

    # Prompt before performing file operation
    if [ "$prompt" != "n" ]; then
      read -n1 -p "Perform this file operation [Y/n/a/q]? " doFileOp; echo
      case $doFileOp in
        n)
          doFileOp='n' ;;
        a)
          prompt='n'
          doFileOp='y' ;;
        q)
          exit 0 ;;
        *)
          doFileOp='y' ;;
      esac
    fi
    
    # Get down to business
    if [ "$doFileOp" == "y" ]; then
      Journal "$fileOpText" 

      # At long last... DO SOMETHING!
      Run mv "$filename" "$newFilename"
      [ $? == 0 ] && (( renameCount++ ))
    fi
  fi
done

# Delete all of the files pending deletion
# Always prompt for confirmation, even if they chose "all" previously
# Do these last so that the renames can run unattended
for file in "${deleteFiles[@]}"; do
  fileOpText="Delete duplicate or extraneous media file: $file"
  read -n1 -p "$(ColorText LRED "$fileOpText") [Y/n/q]? " doFileOp; echo
  case $doFileOp in
    n)
      continue ;;
    q)
      break ;;
  esac
      
  Journal "$fileOpText" 
  Run rm "$file"
  [ $? == 0 ] && (( deleteCount++ ))
done

# Manage the "last run" file marker
echo "${trimPatterns[*]}" > $LastRunFile

Log "Files renamed: $renameCount"
Log "Files deleted: $deleteCount"
