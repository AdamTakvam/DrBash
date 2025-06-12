#!/bin/bash

TestSerializeArray() {
  source ~/lib/lib/arrays.sh

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

    # Execute Test
    result="$(SerializeArray $params "input")"

    # Verify results & report
    echo -n "TestSerializeArray $i: "
    if [ "$result" == "$expOutput" ]; then
      echo "PASSED"
    else
      echo "FAILED"
      echo "  Input     : ${input[*]}"
      echo "  Parameters: $params"
      echo "  Expected  : $expOutput"
      echo "  Got       : $result"
    fi
  done
}

ParseCLI() {
  for p in $@; do
    case "$p" in
      -y)
        runall='y' ;;
    esac
  done
}

ParseCLI

[ -z "$runall" ] && read -t10 -n1 -p "Run SerializeArray() tests [10s] (Y/n)? " choice; echo
[ "$choice" != 'n' ] && TestSerializeArray
