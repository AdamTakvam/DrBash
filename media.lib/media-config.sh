# This script reads the Dr Bash media configuration file: media-scripts.conf
# This file doesn't usually have to be sourced directly because it's sourced from other common include files.

[[ $__mediaconfig ]] && return 0 
declare -g __mediaconfig=1

# source "${DRB_LIB:-/usr/local/lib}/config.sh"
# source "${DRB_LIB:-/usr/local/lib}/logging.sh"

SourceMediaConfigFile() {
  declare -rg MEDIA_CONFIG_FILE="$(ConfigGet_DATA)/media-scripts.conf"
  
  if [ -r "$MEDIA_CONFIG_FILE" ]; then
    source "$MEDIA_CONFIG_FILE"
  else
    LogError "Configuration file does not exist or is not readable: $MEDIA_CONFIG_FILE
Note: The location of the configuration file can be controlled via the DRB_DATA environment variable.

\t2. To suppress this warning, just create an empty file at that location.\n"
  fi
}

MediaConfigFile() {
  printf "%s" "$MEDIA_CONFIG_FILE"
}

# --------------- media-scripts.conf -----------------------

# Default values
declare -rg _MEDIA_USER_DEF="$(whoami)"
declare -rg _MEDIA_GROUP_DEF="users"
declare -rg _MEDIA_REPO_DEF='~/Videos'
declare -rg _MEDIA_STAGING_DEF="$_MEDIA_REPO_DEF/Staging"
declare -rg _MEDIA_EXTS_DEF='mp4 avi'
declare -rg _MEDIA_COMPACT_DEF=true
declare -rg _MEDIA_REPOSEARCH_DEF=true
declare -rg _MEDIA_PLAYLISTS_DEF='~/Videos/Playlists'

# The user to save new media files under
ConfigGet_MEDIA_USER() {
  ConfigGet MEDIA_USER
}

# The group to save new media files under
ConfigGet_MEDIA_GROUP() {
  ConfigGet MEDIA_GROUP
}

# Where you keep your processed media files
ConfigGet_MEDIA_REPO() {
  ConfigGet MEDIA_REPO
}

# Where you put new media files before they've been processed
ConfigGet_MEDIA_STAGING() {
  ConfigGet MEDIA_STAGING
}

# Files containing these strings will be considered media files
#   otherwise, they will not be acted upon by media scripts
ConfigGet_MEDIA_EXTS() {
  ConfigGet MEDIA_EXTS
}

# Succeeds if the file's extension is one of DRB_MEDIA_EXTS (case doesn't matter; a leading dot in the list is fine)
# + $1 = File name
IsMediaFile() {
  [[ "$1" == *.* ]] || return 1
  local -l ext="${1##*.}" e
  local -a exts
  IFS=$' \t\n' read -ra exts <<< "$(ConfigGet_MEDIA_EXTS)"
  for e in "${exts[@]}"; do
    [[ "$ext" == "${e#.}" ]] && return 0
  done
  return 1
}

# Display media properties in compact (one line) form
ConfigGet_MEDIA_COMPACT() {
  ConfigEvalBool "${DRB_MEDIA_COMPACT:-$_MEDIA_COMPACT_DEF}" >/dev/null
  return $?
}

# Directs findvideo to search the media repo instead of $PWD
ConfigGet_MEDIA_REPOSEARCH() {
  ConfigEvalBool "${DRB_MEDIA_REPOSEARCH:-$_MEDIA_REPOSEARCH_DEF}" >/dev/null
  return $?
}

# This is the client-side drive mapping for playlist generation.
ConfigGet_MEDIA_MAP() {
  ConfigGet MEDIA_MAP
}

# Set the drive mapping value (temporary)
ConfigSet_MEDIA_MAP() {
  ConfigSet TEMP DRB_MEDIA_MAP "$1"
}

# The media playlists save directory
ConfigGet_MEDIA_PLAYLISTS() {
  ConfigGet MEDIA_PLAYLISTS
}

# Set the playlist save directory (temporary)
ConfigSet_MEDIA_PLAYLISTS() {
  ConfigSet TEMP DRB_MEDIA_PLAYLISTS "$1"
}

# --------------- Special Config Files -----------------------

declare -rg FILE_ABBR="${DRB_DATA:-.}/media-fixtitle-abbr.shdata"
declare -rg FILE_FILLER="${DRB_DATA:-.}/media-fixtitle-filler.shdata"
declare -rg FILE_PATTERNS="${DRB_DATA:-.}/media-fixtitle-patterns.shdata"
declare -rg FILE_DELETE="${DRB_DATA:-.}/media-fixtitle-delete.shdata"
declare -rg FILE_TAGS="${DRB_DATA:-.}/media-fixtags-tagfixes.shdata"

# Reads a one-entry-per-line data file into an array, skipping blank lines and # comments
# + $1 = The name of the array to fill
# + $2 = The data file
ReadDataFile() {
  local -n _lines="$1"
  readarray -t _lines < <(grep -Ev '^[[:space:]]*(#|$)' "$2")
}

# Common capitalized initialisms used in media filenames
# Data files contain only one entry per line; lines starting with # are comments
# Abbreviations should be capitalized exactly how you want to see them (e.g TX for Texas)
ConfigFile_ABBR() {
  local -n _out="$1"
  [[ -f "$FILE_ABBR" ]] || { LogError "Configuration file not found: $FILE_ABBR"; return 1; }
  [[ -r "$FILE_ABBR" ]] || { LogError "Configuration file cannot be read: $FILE_ABBR"; return 2; }
  ReadDataFile _out "$FILE_ABBR"
}

# Filler words are words like: a, in, to, it
# If you prefer having every word capitalized, then don't include any filler words
ConfigFile_FILLER() {
  local -n _out="$1"
  [[ -f "$FILE_FILLER" ]] || { LogError "Configuration file not found: $FILE_FILLER"; return 1; }
  [[ -r "$FILE_FILLER" ]] || { LogError "Configuration file cannot be read: $FILE_FILLER"; return 2; }
  ReadDataFile _out "$FILE_FILLER"
}

# Trim patterns are extended regular expressions. All text matching any of these patters is removed from the title only (not tags)
# TRIMPATTERNS is not a read-only value because the user can supplement it via cli parameters.
ConfigFile_PATTERNS() {
  local -n _out="$1"
  [[ -f "$FILE_PATTERNS" ]] || { LogError "Configuration file not found: $FILE_PATTERNS"; return 1; }
  [[ -r "$FILE_PATTERNS" ]] || { LogError "Configuration file cannot be read: $FILE_PATTERNS"; return 2; }
  ReadDataFile _out "$FILE_PATTERNS"
}

# DELETEPATTERNS is a collection of regexes run (grep'd) on the full filename.
# Any filename that matches one of these patterns gets marked for deletion
ConfigFile_DELETE() {
  local -n _out="$1"
  [[ -f "$FILE_DELETE" ]] || { LogError "Configuration file not found: $FILE_DELETE"; return 1; }
  [[ -r "$FILE_DELETE" ]] || { LogError "Configuration file cannot be read: $FILE_DELETE"; return 2; }
  ReadDataFile _out "$FILE_DELETE"

  # A pattern that matches an empty string (e.g. "()" or ".*") matches every file name. Drop it.
  local i
  for i in "${!_out[@]}"; do
    if grep -Eq -- "${_out[$i]}" <<< ""; then
      LogError "Ignoring deletion pattern that would match every file: ${_out[$i]}"
      unset "_out[$i]"
    fi
  done
  _out=("${_out[@]}")
}

# Dictionary of patterns of often mistaken tags to their proper tag name
# + $1 = The name of an associative array (declare -A) to load the tag fixes into
# The file holds the right-hand side of an associative array declaration: ([regex]='replacement' ...)
#   Lines starting with # are comments.
ConfigFile_TAGFIXES() {
  local -n _out="$1"

  if [ ! -f "$FILE_TAGS" ]; then
    LogVerbose "Tag Fixes file does not exist. Creating default..."
    printf '%s\n' "# Set of replacement patterns used to normalize media tags." "([favorite]='fav')" > "$FILE_TAGS"
  fi

  # Load the tagfixes data file.
  # eval is what turns the text into array entries; a plain assignment would store the
  #   whole file as a single value under key 0.
  eval "_out=$(grep -Ev '^[[:space:]]*#' "$FILE_TAGS")" || { LogError "Tag Fixes file is not a valid associative array: $FILE_TAGS"; return 1; }
  LogVerbose "Tag Fixes: ${#_out[@]}"
}

# ---------------------- Initialize ---------------------------

SourceMediaConfigFile
