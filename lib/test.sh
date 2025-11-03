# vim: filetype=bash

declare -i fail=0

Raw() {
  if [ "$1" ]; then
    local -a out
    IFS=$'\n' out=($(printf "%s" "$1" | od -c))
    
    if [[ ${#out[@]} == 2 ]]; then
      printf "> %s\n" "${out[0]}"
    else
      printf "\n"
      for (( i=0; $i < ${#out[@]} - 1; i++ )); do
        printf "\t\t> %s\n" "${out[$i]}"
      done
    fi
  fi
}

declare -i testNum=0
declare subTests=false

SetTestName() {
  [[ "$1" ]] || return 99
  local testName="$*"

  printf 'Test %d: %s: ' $(( ++testNum )) "$testName"
}

SetSubtestName() {
  [[ -z "$1" ]] || [[ -z "$2" ]] && return 99
  local testName="$1"
  local subtest_letter="$2"
  [[ $subtest_letter == 'a' ]] && testNum+=1

  printf "Test %d%s: %s: " ${testNum} ${subtest_letter} "$testName" 
}

RunTest() {
  [[ -z "$1" ]] && return 99

  if [[ $1 == '-q' ]]; then
    shift
    $@ 1>/dev/null 2>&1
  elif [[ $1 == '-v' ]]; then
    $@
  else
    $@ 1>/dev/null
  fi
}

Assert() {
  if [[ $1 == 0 ]]; then
    printf "%b\n" "\\033[0;32mPassed!\\033[0m"
  else
    fail=1
    printf "%s\n" "\\033[0;31mFAILED\\033[0m"     # Red
    printf "\t%s\n" "Expected: 0 $(Raw "0")"
    printf "\t%s\n" "Received: ${1:-<null>} $(Raw "$1")"
  fi
}

AssertTrue() {
  Assert "$1"
}

AssertFail() {
  if [[ $1 != 0 ]]; then
    printf "%b\n" "\\033[0;32mPassed!\\033[0m"
  else
    fail=1
    printf "%s\n" "\\033[0;31mFAILED\\033[0m"    # Red
    printf "\t%s\n" "Expected: non-zero $(Raw "42")"
    printf "\t%s\n" "Received: 0 $(Raw "0")"
  fi
}

AssertFalse() {
  AssertFail "$1"
}

AssertEqual() {
  if [[ "$1" == "$2" ]]; then
    printf "%b\n" "\\033[0;32mPassed!\\033[0m"
  else
    fail=1
    printf "%b\n" "\\033[0;31mFAILED\\033[0m"     # Red
    printf "\t%s\n" "Expected: ${1:-<null>} $(Raw "$1")"
    printf "\t%s\n" "Received: ${2:-<null>} $(Raw "$2")"
  fi
}

AssertNotEqual() {
  if [[ "$1" != "$2" ]]; then
    printf "%b\n" "\\033[0;32mPassed!\\033[0m"
  else
    fail=1
    printf "%b\n" "\\033[0;31mFAILED\\033[0m"     # Red
    printf "\t%s\n" "Expected: anything other than: ${1:-<null>} $(Raw "$1")"
    printf "\t%s\n" "Received: the same damn thing!"
  fi
}

AssertSubstring() {
  if grep -Fq "$1" <<< "$2"; then   # You might be tempted to go with a =~ solution here, but...
    printf "%b\n" "\\033[0;32mPassed!\\033[0m"
  else
    fail=1
    printf "%b\n" "\\033[0;31mFAILED\\033[0m"
    printf "\t%s\n" "Expected substring of: ${1:-<null>} $(Raw "$1")"
    printf "\t%s\n" "Received this garbage: ${2:-<null>} $(Raw "$2")"
  fi
}
