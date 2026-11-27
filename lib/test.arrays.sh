#!/bin/bash

source "${DRB_LIB:-.}/cli.sh"
source "${DRB_LIB:-.}/logging.sh"
source "${DRB_LIB:-.}/test.sh"
source "${DRB_LIB:-.}/arrays.sh"

# The arrays that effectively define the tests to be performed
declare -a testInputs=(in1 in1 in1 in1 in1 in1)
declare -a testParams=('' '-q' '-d=,' '-d=| -ds -dS' '-d=*. -ds -d^' '-e')
declare -a testOutputs=('1 2 3' '"1" "2" "3"' '1,2,3' '1 | 2 | 3' '*.1 *.2 *.3' "$(echo -e '1\n2\n3')")

# The input arrays
declare -a in1=( 1 2 3 )
declare -a in2=( 'a 1' 'b 2' 'c 3' )

for (( i=0; i<${#testInputs[*]}; i++ )); do
# Load test data
  declare -n input="${testInputs[$i]}"
  declare params="${testParams[$i]}"
  declare expOutput="${testOutputs[$i]}"

  SetTestName "SerializeArray ${params[@]} (${input[@]}) -> (${expOutput[@]})"
  AssertEqual "${expOutput[@]}" "$(SerializeArray $params "input")"
done

# EditArray, with nullglob on as drbash.sh sets it
shopt -s nullglob

declare -a exts=(mp4 avi)
SetTestName "EditArray -p='*.' adds a glob prefix (nullglob on)"
EditArray -p='*.' exts
AssertEqual '*.mp4 *.avi' "${exts[*]}"

declare -a items=(one two)
SetTestName "EditArray -p and -s keep spaces in the prefix and suffix"
EditArray -p=$'\t* ' -s=' !' items
AssertEqual $'\t* one !|\t* two !' "${items[0]}|${items[1]}"

declare -a words=(apple-1 pear-22)
SetTestName "EditArray -rm and -rr replace matching text in each element"
EditArray -rm='-([0-9]+)' -rr='(\1)' words
AssertEqual 'apple(1) pear(22)' "${words[*]}"

declare -a words2=(apple-1 pear-22)
SetTestName "EditArray -rm without -rr deletes the matching text"
EditArray -rm='-[0-9]+' words2
AssertEqual 'apple pear' "${words2[*]}"

exit $fail
