#!/bin/bash

source "${DRB_LIB:-.}/general.sh"
source "${DRB_LIB:-.}/logging.sh"
source "${DRB_LIB:-.}/run.sh"

declare -i retval=0

Check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    printf "%s: Passed!\n" "$name"
  else
    printf "%s: FAILED\n\texpected: [%s]\n\tactual:   [%s]\n" "$name" "$expected" "$actual"
    retval=1
  fi
}

# Prints each argument on its own line, wrapped in <>, so quoting problems are visible
PrintArgs() { printf "<%s>" "$@"; }

# Deliberately NOT exported: Run() must still be able to call it
TestCommandX() { (( $# == 3 )); }

Run -u TestCommandX a b c
Check "Test 1: Three simple args" 0 "$?"

Run -u TestCommandX "a sp b" "d sp e" f
Check "Test 2: Args containing spaces" 0 "$?"

Check "Test 3: Shell metacharacters are passed through literally" \
  '<$HOME><`id`><a"b><c'"'"'d><*>' \
  "$(Run -u PrintArgs '$HOME' '`id`' 'a"b' "c'd" '*')"

Check "Test 4: Dash-args containing spaces are not split" \
  '<--title=My Movie><-x>' \
  "$(Run -u PrintArgs '--title=My Movie' -x)"

Run -u false
Check "Test 5: Exit code is propagated" 1 "$?"

counter="$(mktemp)"
CountAndFail() { printf x >> "$counter"; return 1; }
QUIET=1 Run -u CountAndFail
Check "Test 6: QUIET doesn't run a failing command twice" x "$(cat "$counter")"
rm -f "$counter"

ExitingFunc() { exit 7; }
Run -u ExitingFunc
Check "Test 7: A function that exits doesn't kill the caller" 7 "$?"

Check "Test 8: stdin mode still evaluates shell syntax" \
  "a|b" \
  "$(printf "%s\n" "printf a; printf '|b'" | Run -u)"

MarkRan() { printf yes; }
Check "Test 9: DEBUG mode doesn't run the command" "" "$(DEBUG=1 Run -u MarkRan 2>/dev/null)"

Run -u this-command-does-not-exist-anywhere 2>/dev/null
Check "Test 10: Missing command returns 98" 98 "$?"

Run -r -u true
Run -u PrintArgs >/dev/null
Check "Test 11: Flags from one call don't leak into the next" "" "${root-}${user-}"

# sudo only searches its own secure_path, so a command found in our PATH must come back as a full path
Check "Test 12: A command in the PATH resolves to its full path" "$(type -P ls)" "$(_Run_FindCmd ls)"

exit $retval
