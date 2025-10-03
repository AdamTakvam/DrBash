[[ -n "${__FILES}" ]] && return 0
__FILES=1

GetDisplayFileSize() {
  [ -z "$1" ] && return
  local size=$1

  local -ir kb=1024
  local -ir mb=$kb*1024
  local -ir gb=$mb*1024

  if (( $size > $gb )); then
    size="$(( $size / $gb )) GB"
  elif (( $size > $mb )); then
    size="$(( $size / $mb )) MB"
  elif (( $size > $kb )); then
    size="$(( $size / $kb )) KB"
  else
    size+="B"
  fi  
  
  printf "%s" "$size"
}

