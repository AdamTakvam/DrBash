# This script reads the Dr Bash media configuration file: media-scripts.conf
# This file doesn't usually have to be sourced directly because it's sourced from other common include files.

[[ $__mediaconfig ]] && return 0 
declare -r __mediaconfig=1

source "${DRB_LIB:-/usr/local/lib}/config.sh"
source "${DRB_LIB:-/usr/local/lib}/logging.sh"

SourceMediaConfigFile() {
  declare -g MEDIA_CONFIG_FILE="$(ConfigGet_DATA)/media-scripts.conf"
  
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
declare -r _MEDIA_USER_DEF="$(whoami)"
declare -r _MEDIA_GROUP_DEF="users"
declare -r _MEDIA_REPO_DEF='~/Videos'
declare -r _MEDIA_STAGING_DEF="$_MEDIA_REPO_DEF/Staging"
declare -r _MEDIA_EXTS_DEF='mp4 avi'
declare -r _MEDIA_COMPACT_DEF=true
declare -r _MEDIA_REPOSEARCH_DEF=true
declare -r _MEDIA_PLAYLISTS_DEF='~/Videos/Playlists'

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
  ConfigSet DRB_MEDIA_MAP "$1"
}

# The media playlists save directory
ConfigGet_MEDIA_PLAYLISTS() {
  ConfigGet MEDIA_PLAYLISTS
}

# Set the playlist save directory (temporary)
ConfigSet_MEDIA_PLAYLISTS() {
  ConfigSet DRB_MEDIA_PLAYLISTS "$1"
}

# --------------- Special Config Files -----------------------

declare -r FILE_ABBR="${DRB_DATA:-.}/media-fixtitle-abbr.shdata"
declare -r FILE_FILLER="${DRB_DATA:-.}/media-fixtitle-filler.shdata"
declare -r FILE_PATTERNS="${DRB_DATA:-.}/media-fixtitle-patterns.shdata"
declare -r FILE_DELETE="${DRB_DATA:-.}/media-fixtitle-delete.shdata"
declare -r FILE_TAGS="${DRB_DATA:-.}/media-fixtags-tagfixes.shdata"

# Common capitalized initialisms used in media filenames
# Data files contain only one ewntry per line
# Abbreviations should be capitalized exactly how you want to see them (e.g TX for Texas)
ConfigFile_ABBR() {
  local -n _out="$1"
  readarray -t _out < "$FILE_ABBR"
}

# Filler words are words like: a, in, to, it
# If you prefer having every word capitalized, then don't include any filler words
ConfigFile_FILLER() {
  local -n _out="$1"
  readarray -t _out < "$FILE_FILLER"
}

# Trim patterns are extended regular expressions. All text matching any of these patters is removed from the title only (not tags)
# TRIMPATTERNS is not a read-only value because the user can supplement it via cli parameters.
ConfigFile_PATTERNS() {
  local -n _out="$1"
  readarray -t _out < "$FILE_PATTERNS" 
}

# DELETEPATTERNS is a collection of regexes run (grep'd) on the full filename.
# Any filename that matches one of these patterns gets marked for deletion
ConfigFile_DELETE() {
  local -n _out="$1"
  readarray -t _out < "$FILE_DELETE"
}

# Dictionary of patterns of often mistaken tags to their proper tag name
ConfigFile_TAGFIXES() {
  local -n _out="$1"

  # Load the tagfixes data file
  if [ -r "$FILE_TAGS" ]; then
    _out="$(cat "$FILE_TAGS")"
    LogVerbose "Tag Fixes: ${#_out[@]}"
  else
    LogVerbose "Tag Fixes file does not exist. Creating default..."
    printf "%b\n" "( [\"movei\"]=\"movie\" )" > "$FILE_TAGS"
  fi
}

# ---------------------- Initialize ---------------------------

SourceMediaConfigFile
