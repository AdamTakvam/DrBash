[[ -n "${__media_props}" ]] && return 0
__media_props=1

# source "${DRB_LIB}/logging.sh"
# source "${DRB_LIB}/run.sh"

# 7680 x 4320 = 33,177,600 (8K)
declare -irg min_8k=20736000
# 3840 x 2160 = 8,294,400 (4K)
declare -irg min_4k=5990400
# 2560 x 1440 = 3,686,400 (1440p)
declare -irg min_1440=2880000
# 1920 x 1080 = 2,073,600 (1080p)
declare -irg min_1080=1497600
# 1280 x 720 = 921,600 (720p)
declare -irg min_720=614400
# 640 x 480 = 307,200 (480p)
declare -irg min_480=240000
# 480 x 320 = 172,800 (320p)
declare -irg min_320=129600
# 360 x 240 = 86,400 (240p)


# Creates a resolution tag for a file
# + $1 = File name
# - stdout = Resolution tag (e.g. "4k", "1080p", etc)
GetResolution() {  
  Requires exiftool
  
  local -r file="$1"
  [[ -z "$file" ]] && return 99

  local IFS=$'\n' 
  local -a rezArr=($(Run -u exiftool -ImageHeight -ImageWidth "$file" | awk '{ printf $4"\n" }'))
  if [ "${#rezArr[@]}" != 2 ]; then
    LogError "Unable to read resolution from: $file (no data)"
    return 1
  fi

  _GetResolution ${rezArr[0]} ${rezArr[1]}
}

# Creates a resolution tag based on the frame geometry on a video
# + $1 = Frame width (no commas!)
# + $2 = Frame height (no commas!)
# - stdout = Resolution tag (e.g. "4k", "1080p", etc)
_GetResolution() {
  local -i w=$1
  local -i h=$2
  [[ $w == 0 || $h == 0 ]] && return 99

  LogVerboseError "Resolution: $w x $h"

  local -i rez=$(( w * h ))

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

declare -g MEDIA_ROOT="$(ConfigGet_MEDIA_REPO)"
declare -ig DISPLAY_FULL_PATH=0

FormatFilename() {
  [[ -z "$1" ]] && return 99
  [[ -f $1 ]] || return 1

  local _name="$1"
  local _coloredSubdirs="${2:-1}"

  if [[ $DISPLAY_FULL_PATH == 1 ]]; then
    printf "%s" "$_name"
  else
    _name="$(echo -n "$_name" | sed -E "s|$MEDIA_ROOT||")"
    if [[ "$_coloredSubdirs" == 1 ]]; then
      local subDir="$(dirname "$_name")"
      if [[ "$subDir" ]] && [[ "$subDir" != '.' ]]; then
        subDir="$(ColorText LBLUE "$subDir")"
        printf "%s" "${subDir}/$(basename "$_name")"
      else
        printf "%s" "$_name"
      fi
    else
      printf "%s" "$_name"
    fi
  fi
}

DisplayMediaProperties() {
  local _info="$1"
  local -i _compact="${2:-0}"
  local _label="$3"

  local nameLine=""
  [ "$_label" ] && nameLine="$_label) "
  nameLine+="$(FormatFilename "$file" 0)"
  Log "$nameLine"

  local s="$(GetDisplayFileSize "$(stat -c%s "$file")")"
  local d="$(echo "$_info" | grep "Duration" | head -n1 | cut -d: -f2)"
  local h="$(echo "$_info" | grep "Height" | head -n1 | cut -d: -f2)"
  local w="$(echo "$_info" | grep "Width" | head -n1 | cut -d: -f2)"

  h="$(echo "${h:1}" | sed -E 's/([0-9]) ([0-9]+)/\1,\2/')"  # Replace space with comma
  w="$(echo "${w:1}" | sed -E 's/([0-9]) ([0-9]+)/\1,\2/')"

  if [[ "$_compact" == 1 ]]; then
    w="$(echo "$w" | cut -d' ' -f1 | sed 's/,//')"              # Remove "pixels"
    h="$(echo "$h" | cut -d' ' -f1 | sed 's/,//')"
    Log "\t${s} | ${d} | ${w} x ${h} ($(_GetResolution $w $h))"
  else
    LogTable "\tSize\t$s
      \tDuration\t$d
      \tHeight\t$h
      \tWidth\t$w"
  fi
}
