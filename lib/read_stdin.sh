[[ -n "$__readstdin" ]] && return
__readstdin=1

# Looks for anything on stdin for 100ms. If nothing is there, returns 1
# Otherwise, whatever is on stdin gets collected and pushed right back out stdout
#
# Note: The only reason to use this is for the timeout. 
# If you don't care about that, then just use 'cat'
# The only issue with cat is that if there's nothing on stdin,
#   it will hang forever.
ReadStdIn() {
  local input=""
  while read -r -t 0.1 _msg; do
    input+="$_msg"
  done

  if [ "${#input}" == 0 ]; then
    return 1
  else
    printf "%s" "$input"
    return 0
  fi
}

