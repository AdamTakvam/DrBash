#!/bin/bash

source "${USERLIB:-$HOME/lib}/run.sh"
source "${USERLIB:-$HOME/lib}/general.sh"

Require libimage-exiftool-perl 

# Do not rely on $0 for multiple reasons:
# 1. It doesn't exist in all cases (just trust me on this one)
# 2. It may reflect the name of symlinks to the command which may differ from what is intended or desired.
# 3. If the file is sourced $0 will be the function name.
declare -r APPNAME="media-fixtags"

PrintHelp () {
  tabs 4
  Log
  Log "Normalizes the tags within the filenames of media files in the current directory, including automatic resolution tagging." 
  Log "This tool does not recurse through subdirectories."
  Log "This tool is intended to be one step in a pipeline of automated media file processing."
  Log
  Log "$(Header "Concept:") This utility is only intended to operate on media files named according to the following convention:"
  LogTable  "\t<title> [<tags>].<ext>
\tWhere:
\t\t<tags> = <media_attributes> <resolution>
\t\t<media_attributes> = Whatever you define
\t\t<resolution> = Exactly one of: 240p, 360p, 480p, 720p, 1080p, 2k, 4k, 6k, 8k"
  Log "Example: 12 Angry Men [classic.movie 2.rank court.drama bob.favorite 720p].mp4"
  Log
  Log "$(Header "Usage:") $APPNAME [OPTIONS...]"
  Log
  LogTable "$(Header "[OPTIONS...]")\t(optional; do not combine)
\t-h\tDisplay this help text.
$(PrintLogHelp -q=0)
\t-s\tSimulate what would be done in a real run (equivalent to -vv).
\t-r\tReevaluate resolution tags for all files
\t-y\tUnattended mode. Assume default responses to all prompts.
\t-st\tDeveloper testing mode.
\t-fs\tForce short run (since .lastrun file modification date).
\t-fl\tForce long run (ignore .lastrun file)."
  Log
  LogTable "$(Header "Data Files:")\t$USERDATA/$APPNAME-tagfixes.shdata
\tAssociative array of extended regular expressions to match with tags (key)
\tand values to replace them with (value)
\tTest with: sed -E s/key/value/
\tFormatted as an associative array definition. For example:
\t( [key1]=value1 \\ 
\t  [key2]=value2 )"
  Log
  Log "$(Header "Filename Normalization:")"
  LogTable "  \t* Reduces multiple sequential space characters to just one space character.
  \t* Ensures all tags are lower-case.
  \t* Normalizes abbreviated tags.
  \t* Any text after the close bracket will be removed."
  Log
  Log "$(Header "Usage Examples:")"
  LogTable "\t* To force a long (all files) run with resolution (re)tagging and verbose logging, do:
\t$APPNAME -v -r -fl
\n
\t* Do NOT:
\t$APPNAME -vrfl
\n
\t* Remove text matching pattern:
\t$APPNAME \"HD\""
  Log
}

# THIS IS TOO DIFFICULT FOR BASH.
# MOVE TO PYTHON
#
# Remove duplicate tags
# $1 = tags[]
# output = dedupedTags[]
# DedupeTags() {
#  declare -a incomingTags=($1)
#  declare -A workingDict
#
  # Add the values from the array as keys in a dictionary 
  # because it will enforce uniqueness
#  for tag in ${incomingTags[*]}; do
#    workingDict+=(["$tag"]='_')
#  done
#
#  echo "${!workingDict[*]}"
#}

# Creates a resolution tag
# $1 = file name
# output = rez

# 7680 x 4320 = 33,177,600 (8K)
let min_8k=20736000
# 3840 x 2160 = 8,294,400 (4K)
let min_4k=5990400
# 2560 x 1440 = 3,686,400 (1440p)
let min_1440=2880000
# 1920 x 1080 = 2,073,600 (1080p)
let min_1080=1497600
# 1280 x 720 = 921,600 (720p)
let min_720=614400
# 640 x 480 = 307,200 (480p)
let min_480=240000
# 480 x 320 = 172,800 (320p)
let min_320=129600
# 360 x 240 = 86,400 (240p)

GetResolution() {  
  declare -r file="$1"
  declare -a rezArr
  IFS=$'\n' rezArr=($(exiftool -ImageHeight -ImageWidth "$file" | awk '{ printf $4"\n" }'))
  if [ "${#rezArr[@]}" != 2 ]; then
    LogError "\n$(ColorText YELLOW "Unable to read resolution from: $file (no data)")"
    return 1
  fi

  LogVerboseError "\nResolution: ${rezArr[0]} x ${rezArr[1]}"

  let rez=$(( ${rezArr[0]} * ${rezArr[1]} ))

  if (( $rez > $min_8k )); then
    echo "8k"
  elif (( $rez > $min_4k )); then
    echo "4k"
  elif (( $rez > $min_1440 )); then
    echo "1440p"
  elif (( $rez > $min_1080 )); then
    echo "1080p"
  elif (( $rez > $min_720 )); then
    echo "720p"
  elif (( $rez > $min_480 )); then
    echo "480p"
  elif (( $rez > $min_320 )); then
    echo "320p"
  else
    echo "240p"
  fi
}

# If tag list does not contain the file resolution,
#   this method will add it
# +$1 = file name
# +$2 = tags list
# +$3 = override flag (any value)
# -stdout = tags array with resolution
EnsureRezTag() {
  local filename="$1"
  local tags="$2"
  local override="$3"
  
  if [ -z "$tags" ]; then
    rez="$(GetResolution "$filename")"
    [ "$?" == 0 ] && echo -n "$rez" || return $?
  elif [ ! "$(echo "$tags" | grep -E '\b[0-9]{3,4}p|\b[2468]k')" ]; then
    rez="$(GetResolution "$filename")"
    [ "$?" == 0 ] && echo -n "$tags $rez" || return $?
  elif [ "$override" ]; then
    rez="$(GetResolution "$filename")"
    [ "$?" != 0 ] && return $?
    # Remove old rez tag
    tags="$(echo "$tags" | sed -E 's/(\b[0-9]{3,4}p|\b[2468]k)//')"
    # Add new rez tag
    echo -n "${tags}${rez}"
  else
    echo -n "$tags"
  fi
}

# Applies static normalization rules to title and tags
# +$1 = file name
# +$2 = resolutiuon tag override flag (any value)
# -stdout = Normalized filename
NormalizeTags() {
  local file="$1"
  local rez_override="$2"
  
  # Parse out the file extension
  IFS='.' fileParts=($file)
  local -l fileExt="${fileParts[-1]}"
  local filename="${file%.$fileExt}"
  
  # Separate the media name from the tags
  IFS='[' fileParts=($filename) 
  local title="${fileParts[0]}"
  local -l tags="$(echo "${fileParts[1]}" | sed 's/\].*//')"

  LogDebugError "\nFile = $file"
  LogDebugError "Title = $title"
  LogDebugError "Tags = $tags"
  LogDebugError "Extension = $fileExt"

  if [ ${#fileParts[*]} -gt 2 ] || [ -z "$title" ]; then
    LogErrorTee "\n$(ColorText LRED "ERROR: Invalid file name: $file\n\tManual intervention required to remove extra square brackets!")"
    return 1
  fi

  # LogDebugError -n "a "

  # Reminder: "${arr[*]}"  <-- Serialization
  #           "${arr[@]}"  <-- Iteration
  #           "${!arr[@]}" <-- Get key values of associative array (hashtable)

  # Perform tag substitutions
  if [ "$tags" ]; then
    for tag in "${!TAGFIXES[@]}"; do
      tagfix="${TAGFIXES["$tag"]}"
      tags="$(echo "$tags" | sed -E "s/$tag/$tagfix/g")"
    done
    unset tagfix
  fi

  # LogDebugError -n "b "
  
  # Add a resolution tag if one doesn't already exist
  tags="$(EnsureRezTag "$file" "$tags" "$rez_override")"
  [ "$?" != 0 ] || [ -z "$tags" ] && return 1 

  # TODO: MOVE TO PYTHON
  # Remove any duplicated tags after the replacements
  #tags="$(DedupeTags "$tags")"

  # LogDebugError -n "c " 
  
  # Recombine media name and tags
  local newFilename="${title}"
  [ "$tags" ] && newFilename+=" [${tags}]"
  newFilename+=".${fileExt:-mp4}"
 
  # Remove any duplicated spaces that may have resulted from deletions
  newFilename="$(echo "$newFilename" | sed -E 's/\s+/ /g' | sed -E 's/(^\s+|\s+$)//g')"

  # LogDebugError "d"
  LogDebugError "\nnewFilename (in function) = $newFilename"

  echo -n "$newFilename"
  return 0
}

ParseCLI() {
  # Parse command line args
  for p in "$@"; do
    case "$p" in
      -h | --help | ?)
        PrintHelp; exit 0 ;;
      -st)
        LogEnableDebug
        let testMode=1 ;;
      -s)
        LogEnableDebug ;;
      -r)
        let rezOverride=1 ;;
      -fs)
        let forceShortRun=1 ;;
      -fl)
        let forceLongRun=1 ;;
      -y)
        let unattended=1 ;;
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
  
  [ $rezOverride ] && Log "Overriding resolution tags on all files."
  LogDebug "Simulation Mode: No changes will be written to disk."
} 

declare -A TAGFIXES=()

ReadConfig() {
  # Load the tagfixes data file
  declare tagFixesFile="$USERDATA/$APPNAME-tagfixes.shdata"
  
  if [ -r "$tagFixesFile" ]; then
    declare -Ar TAGFIXES="$(cat "$tagFixesFile")"
    LogVerbose "TagFixes: ${#TAGFIXES[@]}"
  else
    LogError "Tag fixes data file does not exist or not readable: $tagFixesFile"
    [ $unattended == 1 ] || read -n1 -p "Do you want to continue with just resolution fixing? [y/N]? " choice; echo
    [ "${choice,,}" == 'y' ] || exit 30
  fi
}

declare -a fileSet
declare -r LastRunFileExt="lastrun"
declare -r LastRunFile=".$APPNAME.$LastRunFileExt"

PrepareForRun() {
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
    failReason="the requested text to remove does not match what was previously specified.\nPrevious: $(cat $LastRunFile)\nCurrent:  ${trimPatterns[*]}"
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
    [ $unattended == 1 ] || read -n1 -t10 -p "Are you sure you want to continue [Y/n] (10s)? " cont; echo
    [ "${cont,,}" == 'n' ] && exit 0
  fi
}

declare -l doFileOp='y' prompt='y'
declare -i renameCount=0

FixTags() {
  filename="$1"

  # There are some files we need to ignore
  [ -e "$filename" ] || return 0 # Hack around bash bugs
  [ ${#filename} -lt 5 ] && return 0
  [[ "$filename" =~ .$LastRunFileExt$ ]] && return 0

  newFilename="$(NormalizeTags "$filename" $rezOverride)"
  [ "$?" == 0 ] || return 1 
  
  # Sanity check
  [ -z "$newFilename" ] && { LogError "$(ColorText YELLOW "Internal Error:") NormalizeTags() returned a null filename!"; exit 99; }

  LogDebug "Current file name = $filename\nNew file name = $newFilename"
  
  if [ "$newFilename" == "$filename" ]; then
    Log -n '.'
  else
    progress=`awk -v fileIndex=$fileIndex -v numFiles=${#fileSet[@]} 'BEGIN { printf "%d%\n", (fileIndex/numFiles)*100 }'`
    progress=$(printf %3s $progress)

    declare fileOpText="\nRename: ${filename}\n$progress  => $(ColorText LPURPLE "$newFilename")"
    Log "$fileOpText"
    
    # Force doFileOp to 'n' if this is a simulation
    if [ "$(LogDebugEnabled)" ]; then
      prompt='n'
      doFileOp='n'
    fi

    # Prompt before performing file operation
    if [ "$prompt" != "n" ]; then
      [ $unattended == 1 ] || read -n1 -p "Perform this file operation [Y/n/a/q]? " doFileOp; echo
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
}

WrapUp() {
  [ -z "$1" ] && return 99

  local -n errors="$1"

  # Print error report
  local retval=0
  if [ "${#errors[@]}" -ne 0 ]; then
    retval=1
    Log '\nError Files:'
    for file in "${errors[@]}"; do
      Log "$file"
    done
  else
    Log '\nNo errors detected!'
  fi

  if [ "$retval" -eq 0 ]; then
    # Manage the "last run" file marker
    touch "$LastRunFile"
  fi

  Log "Files renamed: $renameCount"
}

# Begin script execution
# if [ ! "$(IsSourced)" ]; then
ParseCLI "$@"
ReadConfig
PrepareForRun

# --- FILE LOOP ---
declare -a errorFiles=()
for _filename in "${fileSet[@]}"; do
  FixTags "$_filename"
  [ $? -ne 0 ] && errorFiles+=("$_filename")
done

WrapUp errorFiles
