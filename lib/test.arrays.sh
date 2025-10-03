#!/bin/bash

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
