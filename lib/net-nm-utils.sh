# Attempts to bring up the specified connection
getItUp() {
  [ "$1" ] && sudo nmcli conn up "$1"
}

