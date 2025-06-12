# If functuinbs returns success,
# STDIN_DATA will contain the value of stdin
read_stdin () {
  # bash-4.1+
  if [ "$(read -N 1 -t 0.1)" ]; then
	  STDIN_DATA=$STDIN_DATA$(</dev/stdin)
	  export $STDIN_DATA
    exit 0
  fi
  exit 1
}
