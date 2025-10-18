#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/string.sh"
source "${DRB_LIB:-/usr/local/lib}/logging.sh"
source "${DRB_LIB:-/usr/local/lib}/cli.sh"
source "${DRB_LIB:-/usr/local/lib}/test.sh"

# GetParamName()

SetSubtestName 'GetParamName -r=1' 'a'
AssertEqual 'r' "$(GetParamName -r=1)"

SetSubtestName 'GetParamName -r=' 'b'
AssertEqual 'r' "$(GetParamName -r=1)"

SetSubtestName 'GetParamName -r' 'c'
AssertEqual 'r' "$(GetParamName -r=1)"

SetSubtestName 'GetParamName -rf' 'd'
AssertEqual 'rf' "$(GetParamName -rf)"

SetSubtestName 'GetParamName anonParam' 'e'
AssertEqual 'anonParam' "$(GetParamName anonParam)"

# GetParamValue

SetSubtestName 'GetParamValue -v' 'a'
AssertEqual '' "$(GetParamValue -v)"

SetSubtestName 'GetParamValue -v=' 'b'
AssertEqual '' "$(GetParamValue -v=)"

SetSubtestName 'GetParamValue -v=""' 'c'
AssertEqual '' "$(GetParamValue -v="")"

SetSubtestName 'GetParamValue -v=7' 'd'
AssertEqual '7' "$(GetParamValue -v=7)"

SetSubtestName 'GetParamValue -n=apple' 'e'
AssertEqual 'apple' "$(GetParamValue -n=apple)"

SetSubtestName 'GetParamValue -n="Alissa White-Gluz"' 'f'
AssertEqual 'Alissa White-Gluz' "$(GetParamValue -n="Alissa White-Gluz")"

SetSubtestName 'SeparateParameters "a b c" -abc --help' 'a'
declare -a params
SeparateParameters 'params' "a b c" -abc --help
AssertEqual 'a b c' "${params[0]}"
SetSubtestName 'SeparateParameters "a b c" -abc --help' 'b'
AssertEqual '-a' "${params[1]}"
SetSubtestName 'SeparateParameters "a b c" -abc --help' 'c'
AssertEqual '-b' "${params[2]}"
SetSubtestName 'SeparateParameters "a b c" -abc --help' 'd'
AssertEqual '-c' "${params[3]}"
SetSubtestName 'SeparateParameters "a b c" -abc --help' 'e'
AssertEqual '--help' "${params[4]}"

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

declare -a flags anonParams bad
declare -A namedParams

Reset() {
  flag=()
  namedParams=()
  anonParams=()
  bad=()
}

SetSubtestName "ParseParameters -a" 'a'
ParseParameters 'flags' 'namedParams' 'anonParams' -a
AssertEqual 'a' ${flags[0]}
Reset

SetSubtestName 'ParseParameters -a -b -c' 'b'
ParseParameters 'flags' 'namedParams' 'anonParams' -a -b -c
AssertEqual '3' ${#flags[@]}
Reset

SetSubtestName 'ParseParameters -abc' 'c'
ParseParameters 'flags' 'namedParams' 'anonParams' -abc
AssertEqual '3' ${#flags[@]}
Reset

SetSubtestName 'ParseParameters -a=1' 'd'
ParseParameters 'flags' 'namedParams' 'anonParams' -a=1
AssertEqual '1' "${namedParams[a]}"
Reset

SetSubtestName 'ParseParameters -a="1 2"' 'e'
ParseParameters 'flags' 'namedParams' 'anonParams' -a="1 2"
AssertEqual '1 2' "${namedParams[a]}"
Reset

SetSubtestName "echo \"-abc '1 2'\" | ParseParameters --" 'f'
echo "-abc 1 2" | ParseParameters 'flags' 'namedParams' 'anonParams' --
AssertEqual '3' ${#flags[@]}
AssertEqual '1 2' "${anonParams[0]}"
Reset

SetSubtestName 'ParseParameters --name' 'g'
ParseParameters 'flags' 'namedParams' 'anonParams' --name
AssertEqual 'name' "${flags[0]}"
Reset

SetSubtestName 'ParseParameters --name="1 2"' 'h'
ParseParameters 'flags' 'namedParams' 'anonParams' --name="1 2"
AssertEqual '1 2' "${namedParams[name]}"
Reset

SetSubtestName 'ParseParameters a' 'i'
ParseParameters 'flags' 'namedParams' 'anonParams' a
AssertEqual 'a' "${anonParams[0]}"
Reset

SetSubtestName 'ParseParameters "a b"' 'j'
ParseParameters 'flags' 'namedParams' 'anonParams' "a b"
AssertEqual 'a b' "${anonParams[0]}"
Reset

# CombineParams()
SetSubtestName 'CombineParams -a -b -c' 'a'
AssertEqual '-abc' "$(CombineParams -a -b -c)"

SetSubtestName 'CombineParams -ab -c' 'b'
AssertEqual '-abc' "$(CombineParams -ab -c)"

SetSubtestName 'CombineParams -a -b -c zyx 123' 'c'
AssertEqual '-abc zyx 123' "$(CombineParams -a -b -c xyz 123)"

SetSubtestName 'echo "xyz 123" | CombineParams -a -b -c --' 'd'
AssertEqual '-abc zyx 123' "$(echo "xyz 123" | CombineParams -a -b -c --)"

SetSubtestName 'CombineParams -a=1 -b -c zyx 123' 'e'
AssertEqual '-a=1 -bc zyx 123' "$(CombineParams -a=1 -b -c zyx 123)"

SetSubtestName 'CombineParams -a=1 -b -c --longname zyx 123' 'f'
AssertEqual '-a=1 -bc --longname zyx 123' "$(CombineParams -a=1 -b -c --longname zyx 123)"

exit $fail
