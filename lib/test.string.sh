#!/bin/bash

source test.sh
source logging.sh
source string.sh

declare outVar='' input='' expResult=''

PrintArray() {
  local -n _out="$1"
  arrayStr="$(printf '%b,' "${_out[@]}")"
  printf "%s" "${arrayStr::-1}"
}

expResult="a,b,c"
SetTestName "Split(' ' a b c)" 
Split outVar ' ' a b c
AssertEqual "$expResult" "$(PrintArray outVar)"

expResult="a,b,c"
SetTestName "Split('-' a-b-c)" 
Split outVar '-' a-b-c
AssertEqual "$expResult" "$(PrintArray outVar)"

expResult="a b c,d,e"
SetTestName "Split(' ' \"a b c\" d e)"
Split outVar ' ' "a b c" d e
AssertEqual "$expResult" "$(PrintArray outVar)"

expResult="/media,Z"
SetTestName "Split('=' /media=Z)"
Split outVar = "/media=Z"
AssertEqual "$expResult" "$(PrintArray outVar)"

expResult=$' \t\n'
ResetIFS
SetTestName "Split() IFS uncorruption"
Split outVar '-' 'a-b-c'
AssertEqual "$expResult" "$IFS"

expResult='a,*,c'
SetTestName "Split() no filename expansion"
Split outVar ' ' a '*' c
AssertEqual "$expResult" "$(PrintArray outVar)"

