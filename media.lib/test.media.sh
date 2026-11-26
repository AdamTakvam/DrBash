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

# Removal and deletion patterns: none, so they can't affect the results
touch "$DRB_DATA/media-fixtitle-patterns.shdata" "$DRB_DATA/media-fixtitle-delete.shdata"

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

SetTestName "Installer creates the filler word list, one word per line"
readarray -t words < "$DRB_DATA/media-fixtitle-filler.shdata"
AssertEqual "28 a out" "${#words[@]} ${words[0]} ${words[-1]}"

SetTestName "Installer creates the abbreviation list, one word per line"
readarray -t words < "$DRB_DATA/media-fixtitle-abbr.shdata"
AssertEqual "HD VHS DVD HD-DVD VOD PG PG-13 XXX" "${words[*]}"

SetTestName "Installer creates the tag fixes example"
AssertEqual "([favorite]='fav')" "$(cat "$TAGFIXES_FILE")"

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

SetTestName "media-fixtags creates the default tag fixes file when it's missing"
rm "$TAGFIXES_FILE"
NewMediaDir "Movie [favorite 480p].mp4"
RunMedia media-fixtags -fl -y "Movie [favorite 480p].mp4"
AssertEqual "([favorite]='fav')" "$(cat "$TAGFIXES_FILE" 2>&1)"

SetTestName "media-fixtags applies the default it just created"
AssertEqual "Movie [fav 480p].mp4" "$(ls)"

SetTestName "media-fixtags reports a malformed tag fixes file"
echo "([oops]='x'" > "$TAGFIXES_FILE"
NewMediaDir "Movie [favorite 480p].mp4"
RunMedia media-fixtags -fl -y "Movie [favorite 480p].mp4"
AssertSubstring "not a valid associative array" "$OUT"

SetTestName "media-fixtags leaves files alone when the tag fixes file is malformed"
AssertEqual "Movie [favorite 480p].mp4" "$(ls)"
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

# ---------- media-fixtitle: whole script ----------

SetTestName "media-fixtitle renames a file that needs it and leaves a correct one alone"
NewMediaDir "the lord of the rings [fav 1080p].mp4" "Already Fine [x 720p].mp4"
RunMedia media-fixtitle -fl "the lord of the rings [fav 1080p].mp4" "Already Fine [x 720p].mp4"
AssertEqual $'Already Fine [x 720p].mp4\nThe Lord of the Rings [fav 1080p].mp4' "$(ls)"

SetTestName "media-fixtitle exits 0 when every file succeeds"
AssertEqual 0 "$RC"

SetTestName "media-fixtitle doesn't count a successful rename as a failure"
AssertSubstring "Files failed: 0" "$OUT"

SetTestName "media-fixtitle simulation (-s) doesn't rename"
NewMediaDir "the lord of the rings [fav 1080p].mp4"
RunMedia media-fixtitle -s -fl "the lord of the rings [fav 1080p].mp4"
AssertEqual "the lord of the rings [fav 1080p].mp4" "$(ls)"

exit $fail
