# Populates specified array with the names of all configured network interfaces
#   or prints them to stdout if no array specified.
# + $1 = (opt) The name of the array the will hold the interface names
# - stdout = If no array name passed in, the interface names. One per line.
getInterfaces () {
  [ "$1" ] && declare -n interfaces="$1" || declare -a interfaces=()

  interfaces+=($(ip addr | grep '^[1-9]' |  awk '{ print $2 }' | sed 's/://'))

  if [ -z "$1" ]; then
    for i in "${interfaces[@]}"; do
      echo "$i"
    done
  fi
}
