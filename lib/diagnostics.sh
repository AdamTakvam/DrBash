# Suite of functions related to diagnosing and debugging scripts

AssertEqual() {
  local -a argv=("$@")
  local -i i
  for (( i=1; i<${#argv[@]}; i++ )); do
    [[ "${argv[$i-1]}" == "${argv[$i]}" ]] || exit 99
  done
}

AssertNotEqual() {
  local -a argv=("$@")
  local -i i
  for (( i=1; i<${#argv[@]}; i++ )); do
    [[ "${argv[$i-1]}" != "${argv[$i]}" ]] || exit 99
  done
}

AssertNull() {
  for x in "$@"; do
    [[ -z "$x" ]] || exit 99
  done
}

AssertNotNull() {
  for x in "$@"; do
    [[ -n "$x" ]] || exit 99
  done
}


