# vim: filetype=bash

[[ -n $__net ]] && return 0
declare -g __net=1

# Populates specified array with the names of all configured network interfaces
#   or prints them to stdout if no array specified.
# + $1 = (opt) The name of the array the will hold the interface names
# - stdout = If no array name passed in, the interface names. One per line.
GetInterfaces () {
  [ "$1" ] && local -n interfaces="$1" || local -a interfaces=()

  interfaces+=($(ip addr | grep '^[1-9]' |  awk '{ print $2 }' | sed 's/://'))

  if [[ -z "$1" ]]; then
    for int in "${interfaces[@]}"; do
      printf '%s\n' "$int"
    done
    unset int
  fi
}

# Attempts to bring up the specified connection
# + $1 = A NetworkManager connection ID
RaiseConnection() {
  [[ -n "$1" ]] && sudo nmcli conn up "$1"
}
