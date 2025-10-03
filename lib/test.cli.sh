#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/cli.sh"
source "${DRB_LIB:-/usr/local/lib}/test.sh"

KeyExists() {
  local -n _array=$1
  local _key="$2"

  if [[ -v ${_array[$key]} ]]; then
    printf "%s" "$key"
    return 0
  else
    return 1
  fi
}

# GetParamName()

SetTestName 'GetParamName -r=1'
AssertEqual 'r' "$(GetParamName -r=1)"

SetTestName 'GetParamName -r='
AssertEqual 'r' "$(GetParamName -r=1)"

SetTestName 'GetParamName -r'
AssertEqual 'r' "$(GetParamName -r=1)"

SetTestName 'GetParamName -rf'
AssertEqual 'rf' "$(GetParamName -rf)"

SetTestName 'GetParamName anonParam'
AssertEqual 'anonParam' "$(GetParamName anonParam)"

# GetParamValue

SetTestName 'GetParamValue -v'
AssertEqual '' "$(GetParamValue -v)"

SetTestName 'GetParamValue -v='
AssertEqual '' "$(GetParamValue -v=)"

SetTestName 'GetParamValue -v=""'
AssertEqual '' "$(GetParamValue -v="")"

SetTestName 'GetParamValue -v=7'
AssertEqual '7' "$(GetParamValue -v=7)"

SetTestName 'GetParamValue -n=apple'
AssertEqual 'apple' "$(GetParamValue -n=apple)"

SetTestName 'GetParamValue -n="Alissa White-Gluz"'
AssertEqual 'Alissa White-Gluz' "$(GetParamValue -n="Alissa White-Gluz")"

# + $1 = The name of an array defined in the caller's scope to populate with flags.
# + $2 = The name of an associative array to populate with named parameters.
# + $3 = The name of an array to populate with stand-alone/anonymous parameters.
#
# Parameter style   Parses As
# ---------------   ---------
# -a -b -c          ${1[0]}=a ${1[1}]=b ${1[2]}=c
# -abc              ${1[0]}=a ${1[1}]=b ${1[2]}=c 
# -a=value          ${2[a]}=value
# -a="v1 v2"        ${2[a]}="v1 v2"
# --name            ${1[0]}="name"
# --name='value'    ${2[name]}="value"
# --                ${3[@]}=(stdin)     (separate values indicated by spaces, quotes, or line feeds
# value1 value2     ${3[0]}="value1" ${3[1]}="value2"
# "value1 value2"   ${3[0]}="value1 value2"

declare -a flags anonParams
declare -A namedParams
declare -i n=1

SetTestName "ParseParameters -a"
ParseParameters 'flags' 'namedParams' 'anonParams' '-a'
AssertEqual 'a' ${flags[0]}
flags=()

SetSubtestName 'ParseParameters -abc' 'a'
ParseParameters 'flags' 'namedParams' 'anonParams' -abc
AssertEqual 'a' "$(KeyExists 'flags' 'a')"

SetSubtestName 'ParseParameters -abc' 'b'
AssertEqual 'a' "$(KeyExists 'flags' 'b')"

SetSubtestName 'ParseParameters -abc' 'c'
AssertEqual 'a' "$(KeyExists 'flags' 'c')"
flags=()

SetSubtestName 'ParseParameters -a xyz' 'a'
AssertEqual '1' "${#flags[@]}"
flags=()

SetSubtestName 'ParseParameters -a=xyz' 'a'
ParseParameters 'flags' 'namedParams' 'anonParams' -a=xyz
AssertEqual 'a' "$(KeyExists 'flags' 'a')"

SetSubtestName 'ParseParameters -a=xyz' 'b'
AssertEqual 'xyz' "${flags[a]}"

SetSubtestName 'ParseParameters -a=xyz' 'c'
AssertEqual '1' "${#flags[@]}"
flags=()

# CombineParams()
SetTestName "CombineParams '-a -b -c'"
AssertEqual '-abc' "$(CombineParams '-a -b -c')"

SetTestName "CombineParams '-ab -c'"
AssertEqual '-abc' "$(CombineParams '-ab -c')"

SetTestName "CombineParams '-a -b -c zyx 123'"
AssertEqual '-abc zyx 123' "$(CombineParams '-a -b -c xyz 123')"

SetTestName "CombineParams '-a -b -c zyx 123 --'"
AssertEqual '-abc zyx 123 --' "$(CombineParams '-a -b -c xyz 123 --')"

SetTestName "CombineParams '-a=1 -b -c zyx 123'"
AssertEqual '-a=1 -bc zyx 123' "$(CombineParams '-a=1 -b -c zyx 123')"

SetTestName "CombineParams '-a=1 -b -c zyx 123 --longname'"
AssertEqual '-a=1 -bc zyx 123 --longname' "$(CombineParams '-a=1 -b -c zyx 123 --longname')"

exit $fail
