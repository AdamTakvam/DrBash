[[ -n "$__playlist" ]] && return
__playlist=1

source "${USERLIB:-$HOME/lib}/general.sh"

# The functions starting with underscaore are intended for internal use only
_PlaylistHelp() {
  tabs 4
  LogUnderline 'PlayList Help:' '#'
  Log "In order to generate a Windows Media Player playlist, it is necessary to have a mapping betwwen the path to the media files on this computer and how they are mapped on the Windows computer where you wish to view the media."
  Log "Unfortunately, creation of playlists for Mac and Linux clients is not currently supported."
  Log "To create the mapping, you need sudo permissions on this server."
  Log
  LogHeader "Document mapping:"
  Log "1. \'sudo [editor] /etc/samba/smb.conf\'"
  Log "2. Scroll to the last section in the file where the shares are defined."
  Log "3. On the line immediately above the share name (in square braces), add a comment:"
  Log "\t# DriveLetter: [letter]"
  Log "4. Repeat for all volumes you have mapped"
  Log
  LogHeader "Example:"
  Log "\t# DriveLetter: Z"
  Log "\t[media]"
  Log "\tpath = /var/media"
  Log
  LogHeader "Notes:"
  Log "\t* If you have multiple clients that you want to make playlists for, it is necessary that they all map the same shares to the same drives."
  Log "\t* This is a last-ditch help message coming to you from a library. Whichever script you ran this from has the ability to specify share mappings in any way it wants to, but evidently chose not to. So if this seems prohibitively rigid to you, take it up with the people who wrote the script you're using."
}

_GetShareMap() {
  [ "$1" ] && return

  local -n pathMap="$1"
  local -r confFile="/etc/samba/smb.conf"
 
  # ${BASH_REMATCH[1]} = Result of previous regex match expression

  # Step 1: Parse smb.conf
  currentDrive=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^#\ DriveLetter:\ ([A-Z]): ]]; then
      currentDrive="${BASH_REMATCH[1]}:"
    elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.*) ]]; then
      [[ -n "$currentDrive" ]] \
        && pathMap["${BASH_REMATCH[1]}"]="$currentDrive" \
        && currentDrive=""
    fi
  done < "$confFile"

  [ "${#pathMap[@]}" == 0 ] && return 1 || return 0
}

# Creates a Windows Media Player-compatible playlist file
# + $1 = Name of an array containing media file namnes defined in parent scope.
# + $2 = (optional) Name of an assoc array containing mapping of local paths to mapped drive letters on Windows clients
# + PLAYLIST_STRICT = Set to any value to cause playlist generation to fail if any media files are located at a path that isn't mapped to a drive letter.
# + PLAYLIST_TITLE = What would you like to name this playlist?
# + PLAYLIST_FILE = Fully-qualified path to save the playlist [default=~/$PLAYLIST_TITLE.wpl]
# #                 If the title ends in '.wpl'then the playlist will be saved in that file.
#                   Otherwise, we'll assume that you've speecified a directory and we'll create a $PLAYLIST_TITLE.wpl file in it.
# - return = 0 = Playlist created successfully.
# -          1 = Configuration error. Print stdout to the display
#            2 = $PLAYLIST_STRICT was set and generation encountered a file in an unmapoped location (message printed to stderr)
#            99 = It doesn't matter what I write here because this code means that you didn't bother to read any of this!
# - stdout = If return code = 0, this will contain the fully-qualified path to your new playlist. If not 0, see above.
# - stderr = Warnings encountered during playlist creation.
CreatePlaylist() {
  Require samba

  [ -z "$1" ] && return 99

  local -n files="$1"

  if [ -z "$2" ]; then
    local -A shareMap
    _GetShareMap "shareMap"
    if [ $? != 0 ]; then
      _PlaylistHelp
      return 1
    fi
  else
    declare -n shareMap="$2"
  fi

  for k in "${!shareMap[@]}"; do 
    LogDebugError "$k → ${shareMap[$k]}"; 
  done
  
  # Step 3: Playlist output
  title="${PLAYLIST_TITLE:-My Playlist}"
 
  if [ -z "$PLAYLIST_FILE" ]; then
    outfile="$HOME/$title.wpl"
  elif [[ "$PLAYLIST_FILE" =~ .wpl$ ]]; then
    outfile="$PLAYLIST_FILE"
  else
    outfile="$PLAYLIST_FILE/$title.wpl"
  fi

  # Sanitize $outfile
  outDir="$(dirname "$outfile")"
  [ ! -d "$outDir" ] && mkdir -p "$outDir"
  unset outDir

  {
    echo '<?wpl version="1.0"?>'
    echo '<smil>'
    echo '  <head>'
    echo "    <title>${title}</title>"
    echo '  </head>'
    echo '  <body>'
    echo '    <seq>'
  
    for f in "${files[@]}"; do
      replaced=false
      for p in "${!shareMap[@]}"; do
        if [[ "$f" == "$p"* ]]; then
          winpath="${f/$p/${shareMap[$p]}}"
          replaced=true
          break
        fi
      done

      if [[ "$replaced" = false ]]; then
        LogError "File $f is in a location with no mapping from Windows clients [skipping]"
        [ "$PLAYLIST_STRICT" ] && return 2 || continue
      fi

      # Normalize slashes
      winpath=$(echo "$winpath" | sed 's|/|\\|g')
  
      # Escape XML chars
      escpath=$(echo "$winpath" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/\"/&quot;/g')
      echo "      <media src=\"$escpath\"/>"
    done
  
    echo '    </seq>'
    echo '  </body>'
    echo '</smil>'
  } > "$outfile"
  
  echo "$outfile"
  unset title outfile winpath escpath
}
