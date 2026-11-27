#!/bin/bash

# Functional tests for the media scripts (media-fixtags, media-fixtitle) and the
#   media data files the installer creates.
# Every test runs the real scripts against throwaway files in a temp directory.
# Run from anywhere: bash media.lib/test.media.sh
# Note: media-fixtags Requires libimage-exiftool-perl and will install it if it's missing.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export DRB_LIB="$REPO/lib"
export DRB_SRC="$REPO"
export DRB_MEDIA_LIB="$REPO/media.lib"
export DRB_EDITION=Full

source "$DRB_LIB/test.sh"

# A throwaway config directory, set up the way the installer would
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export DRB_DATA="$TMP/data"
mkdir -p "$DRB_DATA"
touch "$DRB_DATA/global.conf" "$DRB_DATA/media-scripts.conf"

# Load the installer's function without running the installer
eval "$(sed -n '/^InstallMediaConfig()/,/^}/p' "$REPO/install.sh")"

TAGFIXES_FILE="$DRB_DATA/media-fixtags-tagfixes.shdata"

# Creates a fresh, empty media directory, makes it current, and touches the files named
NewMediaDir() {
  MEDIA="$(mktemp -d -p "$TMP")"
  cd "$MEDIA" || exit 99
  local f
  for f in "$@"; do touch "$f"; done
}

# Runs a media script in the current directory. Output in $OUT, return code in $RC.
RunMedia() {
  local script="$1"; shift
  OUT="$(bash "$REPO/media.shd/$script.sh" "$@" </dev/null 2>&1)"
  RC=$?
}

# Runs NormalizeTitle() from media-fixtitle on one file name
NormalizeTitle() {
  bash -c 'source "$1"; ReadConfig; NormalizeTitle "$2"' _ "$REPO/media.shd/media-fixtitle.sh" "$1" 2>/dev/null
}

# ---------- Installer: media data files ----------

InstallMediaConfig

SetTestName "Installer creates the filler word list: a comment, then one word per line"
readarray -t words < "$DRB_DATA/media-fixtitle-filler.shdata"
AssertEqual "29|# Set of words that should appear in lowercase in media titles.|a|out" "${#words[@]}|${words[0]}|${words[1]}|${words[-1]}"

SetTestName "Installer creates the abbreviation list: a comment, then one word per line"
readarray -t words < "$DRB_DATA/media-fixtitle-abbr.shdata"
AssertEqual "# Set of abbreviations or other words that should appear in all caps in media titles.|HD VHS DVD HD-DVD VOD PG PG-13 XXX" "${words[0]}|${words[*]:1}"

SetTestName "Installer creates the removal patterns file: a comment and ()"
AssertEqual $'# Set of words or regex patterns that will be removed from media titles.\n()' "$(cat "$DRB_DATA/media-fixtitle-patterns.shdata")"

SetTestName "Installer creates the deletion patterns file: a comment, backup files (~), partial downloads (.part)"
AssertEqual "# Set of words or regex patterns that if matched in a media file's title will cause it to be deleted. This is usually only used for backup and temporary files."$'\n~$\n\\.part$' "$(cat "$DRB_DATA/media-fixtitle-delete.shdata")"

SetTestName "Installer creates the tag fixes example: a comment and one fix"
AssertEqual $'# Set of replacement patterns used to normalize media tags.\n([favorite]=\'fav\')' "$(cat "$TAGFIXES_FILE")"

SetTestName "Installer doesn't overwrite existing data files"
echo "mine" > "$DRB_DATA/media-fixtitle-abbr.shdata"
InstallMediaConfig
AssertEqual "mine" "$(cat "$DRB_DATA/media-fixtitle-abbr.shdata")"
rm "$DRB_DATA/media-fixtitle-abbr.shdata"
InstallMediaConfig

# ---------- media-fixtags ----------
# Every test file already has a resolution tag, so the resolution never has to be probed.

SetTestName "media-fixtags applies a tag fix"
NewMediaDir "Movie [favorite 1080p].mp4"
RunMedia media-fixtags -fl -y "Movie [favorite 1080p].mp4"
AssertEqual "0 Movie [fav 1080p].mp4" "$RC $(ls)"

SetTestName "media-fixtags doesn't report a successful rename as an error"
AssertSubstring "No errors detected!" "$OUT"

SetTestName "media-fixtags counts the rename"
AssertSubstring "Files renamed: 1" "$OUT"

SetTestName "media-fixtags leaves tags without a fix alone"
NewMediaDir "Other [classic 720p].mp4"
RunMedia media-fixtags -fl -y "Other [classic 720p].mp4"
AssertEqual "0 Other [classic 720p].mp4" "$RC $(ls)"

SetTestName "media-fixtags simulation (-s) doesn't rename"
NewMediaDir "Movie [favorite 1080p].mp4"
RunMedia media-fixtags -s -fl -y "Movie [favorite 1080p].mp4"
AssertEqual "Movie [favorite 1080p].mp4" "$(ls)"

SetTestName "media-fixtags applies several regex tag fixes from a multi-line file"
cp "$TAGFIXES_FILE" "$TMP/tagfixes.bak"
cat > "$TAGFIXES_FILE" <<'EOF'
( \
  ["compilation"]="comp" \
  ["(adam\.fav|fav\.adam)"]="fav" \
)
EOF
NewMediaDir "Clip [compilation adam.fav 720p].mp4"
RunMedia media-fixtags -fl -y "Clip [compilation adam.fav 720p].mp4"
AssertEqual "0 Clip [comp fav 720p].mp4" "$RC $(ls)"

SetTestName "media-fixtags creates the default tag fixes file when it's missing, same as the installer's"
rm "$TAGFIXES_FILE"
NewMediaDir "Movie [favorite 480p].mp4"
RunMedia media-fixtags -fl -y "Movie [favorite 480p].mp4"
AssertEqual "$(cat "$TMP/tagfixes.bak")" "$(cat "$TAGFIXES_FILE" 2>&1)"

SetTestName "media-fixtags applies the default it just created"
AssertEqual "Movie [fav 480p].mp4" "$(ls)"

SetTestName "media-fixtags reports a malformed tag fixes file"
echo "([oops]='x'" > "$TAGFIXES_FILE"
NewMediaDir "Movie [favorite 480p].mp4"
RunMedia media-fixtags -fl -y "Movie [favorite 480p].mp4"
AssertSubstring "not a valid associative array" "$OUT"

SetTestName "media-fixtags leaves files alone when the tag fixes file is malformed"
AssertEqual "Movie [favorite 480p].mp4" "$(ls)"

cat > "$TAGFIXES_FILE" <<'EOF'
(
  ['(^|\s)(scifi|sf)(\s|$)']='\1sci.fi\3'
  ['\sdocumentary\s']=' doc '
  ['(^|\s)(noir)(\s|$)']='\1film.noir\3'
  ['(^|\s)(romcom)(\s|$)']='\1romance comedy\3'
  ['bad(']='x'
)
EOF

SetTestName "media-fixtags fixes neighbouring tags in one run, with either whole-tag style"
NewMediaDir "Clip [scifi documentary noir 720p].mp4"
RunMedia media-fixtags -fl -y "Clip [scifi documentary noir 720p].mp4"
AssertEqual "0 Clip [sci.fi doc film.noir 720p].mp4" "$RC $(ls)"

SetTestName "media-fixtags removes duplicate tags, keeping the first, including ones a fix splits off"
NewMediaDir "Clip [classic comedy classic romcom 720p].mp4"
RunMedia media-fixtags -fl -y "Clip [classic comedy classic romcom 720p].mp4"
AssertEqual "0 Clip [classic comedy romance 720p].mp4" "$RC $(ls)"

SetTestName "media-fixtags reports a fix sed rejects and still applies the others"
AssertSubstring "Ignoring tag fix that sed rejects: [bad(]='x'" "$OUT"

cp "$TMP/tagfixes.bak" "$TAGFIXES_FILE"

# ---------- media-fixtitle: NormalizeTitle() ----------

SetTestName "NormalizeTitle capitalizes words and keeps filler words lowercase"
AssertEqual "The Lord of the Rings [fav 1080p].mp4" "$(NormalizeTitle "the lord of the rings [fav 1080p].mp4")"

SetTestName "NormalizeTitle turns underscores into spaces"
AssertEqual "Lord of the Rings [fav 1080p].mp4" "$(NormalizeTitle "lord_of_the_rings [fav 1080p].mp4")"

SetTestName "NormalizeTitle turns hyphens into spaces when the title has no spaces"
AssertEqual "Star Wars [fav 720p].mp4" "$(NormalizeTitle "star-wars [fav 720p].mp4")"

SetTestName "NormalizeTitle capitalizes the first word even if it's a filler word"
AssertEqual "A Tale of Two Cities [x 480p].mp4" "$(NormalizeTitle "a tale of two cities [x 480p].mp4")"

SetTestName "NormalizeTitle upper-cases abbreviations, hyphenated ones too"
AssertEqual "PG-13 Rated VHS Rip on HD-DVD [t 480p].mp4" "$(NormalizeTitle "pg-13 rated vhs rip on hd-dvd [t 480p].mp4")"

SetTestName "NormalizeTitle squeezes repeated spaces"
AssertEqual "Movie with Spaces [t 720p].mp4" "$(NormalizeTitle "movie   with  spaces [t 720p].mp4")"

SetTestName "NormalizeTitle lower-cases the extension"
AssertEqual "Loud [t 720p].mp4" "$(NormalizeTitle "loud [t 720p].MP4")"

SetTestName "NormalizeTitle handles a name without tags"
AssertEqual "No Tags Here.mp4" "$(NormalizeTitle "no tags here.mp4")"

SetTestName "NormalizeTitle ignores the comment lines in the word lists"
# Every word here is in the abbreviation or filler file's comment line
AssertEqual "Set All Other Words That Should Appear Media Titles [t 720p].mp4" "$(NormalizeTitle "set all other words that should appear media titles [t 720p].mp4")"

# ---------- media-fixtitle: whole script ----------

SetTestName "media-fixtitle renames a file that needs it and leaves a correct one alone"
NewMediaDir "the lord of the rings [fav 1080p].mp4" "Already Fine [x 720p].mp4"
RunMedia media-fixtitle -fl "the lord of the rings [fav 1080p].mp4" "Already Fine [x 720p].mp4"
AssertEqual $'Already Fine [x 720p].mp4\nThe Lord of the Rings [fav 1080p].mp4' "$(ls)"

SetTestName "media-fixtitle exits 0 when every file succeeds"
AssertEqual 0 "$RC"

SetTestName "media-fixtitle doesn't count a successful rename as a failure"
AssertSubstring "Files failed: 0" "$OUT"

SetTestName "media-fixtitle deletes backup (~) and partial (.part) files and keeps the rest"
# No input means the deletion prompt takes its default: yes
NewMediaDir "Keeper [x 720p].mp4" "Keeper [x 720p].mp4~" "Download [x 720p].mp4.part"
RunMedia media-fixtitle -fl "Keeper [x 720p].mp4" "Keeper [x 720p].mp4~" "Download [x 720p].mp4.part"
AssertEqual "0 Keeper [x 720p].mp4" "$RC $(ls)"

SetTestName "media-fixtitle counts the deletions"
AssertSubstring "Files deleted: 2" "$OUT"

SetTestName "media-fixtitle ignores a deletion pattern that would match every file"
cp "$DRB_DATA/media-fixtitle-delete.shdata" "$TMP/delete.bak"
echo "()" > "$DRB_DATA/media-fixtitle-delete.shdata"
NewMediaDir "Keeper [x 720p].mp4"
RunMedia media-fixtitle -fl "Keeper [x 720p].mp4"
AssertEqual "0 Keeper [x 720p].mp4" "$RC $(ls)"

SetTestName "media-fixtitle warns about the ignored pattern"
AssertSubstring "Ignoring deletion pattern that would match every file: ()" "$OUT"
cp "$TMP/delete.bak" "$DRB_DATA/media-fixtitle-delete.shdata"

SetTestName "media-fixtitle simulation (-s) doesn't rename"
NewMediaDir "the lord of the rings [fav 1080p].mp4"
RunMedia media-fixtitle -s -fl "the lord of the rings [fav 1080p].mp4"
AssertEqual "the lord of the rings [fav 1080p].mp4" "$(ls)"

# ---------- drbashctl: word lists ----------

SetTestName "drbashctl adds a word to a list and keeps the comment on top"
cp "$DRB_DATA/media-fixtitle-abbr.shdata" "$TMP/abbr.bak"
bash "$REPO/system.shd/drbashctl.sh" upper 4K </dev/null >/dev/null 2>&1
readarray -t words < "$DRB_DATA/media-fixtitle-abbr.shdata"
AssertEqual "# Set of abbreviations or other words that should appear in all caps in media titles.|4K DVD HD HD-DVD PG PG-13 VHS VOD XXX" "${words[0]}|${words[*]:1}"
cp "$TMP/abbr.bak" "$DRB_DATA/media-fixtitle-abbr.shdata"

exit $fail
