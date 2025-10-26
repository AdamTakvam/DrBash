#!/bin/bash

source "$DRB_LIB/test.sh"
source "$DRB_LIB/logging.sh"
source "$DRB_LIB/general.sh"
source "$DRB_LIB/datatypes.sh"

DoIndirectTest() {
  local functionName="$1"
  local -n indirectVar="$2"
  local _result="$("$functionName" 'indirectVar')"
  printf '%s' "$_result"
}

# Types
declare stringVar='x'
declare -i intVar=42
declare -a arrayVar=(bite me)
declare -A dictVar=(['key']='value')

SetSubtestName "GetVarType <string>" 'a'
AssertEqual "string" "$(GetVarType 'stringVar')"

SetSubtestName "GetVarType <integer>" 'b'
AssertEqual "integer" "$(GetVarType 'intVar')"

SetSubtestName "GetVarType <array>" 'c'
AssertEqual "array" "$(GetVarType 'arrayVar')"

SetSubtestName "GetVarType <dictionary>" 'd'
AssertEqual "dictionary" "$(GetVarType 'dictVar')"

SetSubtestName "GetVarType <array_reference>" 'e'
AssertEqual "array" "$(DoIndirectTest GetVarType 'arrayVar')"

# Scopes
declare regularVar='--'
declare -g globalVar='g'
declare -x exportedVar='x'
declare -gx gplusxVar='g+x'

SetSubtestName "GetVarScope <regular>" 'a'
AssertEqual "global" "$(GetVarScope 'regularVar')"

SetSubtestName "GetVarScope <global>" 'b'
AssertEqual "global" "$(GetVarScope 'globalVar')"

SetSubtestName "GetVarScope <exported>" 'c'
AssertEqual "exported" "$(GetVarScope 'exportedVar')"

SetSubtestName "GetVarScope <global+exported>" 'd'
AssertEqual "exported" "$(GetVarScope 'gplusxVar')"

SetSubtestName "GetVarScope <exported_reference>" 'e'
AssertEqual "exported" "$(DoIndirectTest GetVarScope 'gplusxVar')"

# Access
declare -r readonlyVar='read this!'

SetSubtestName "GetVarAccess <regular>" 'a'
AssertEqual "readwrite" "$(GetVarAccess 'regularVar')"

SetSubtestName "GetVarAccess <read-only>" 'b'
AssertEqual "read" "$(GetVarAccess 'readonlyVar')"

SetSubtestName "GetVarAccess <read-only_reference>" 'c'
AssertEqual "read" "$(DoIndirectTest GetVarAccess 'readonlyVar')"

# Casing
declare -u uppercaseVar='GET UP'
declare -l lowercaseVar='get low'

SetSubtestName "GetVarCase <regular>" 'a'
AssertEqual "mixedcase" "$(GetVarCase 'regularVar')"

SetSubtestName "GetVarCase <uppercase>" 'b'
AssertEqual "uppercase" "$(GetVarCase 'uppercaseVar')"

SetSubtestName "GetVarCase <lowercase>" 'c'
AssertEqual "lowercase" "$(GetVarCase 'lowercaseVar')"

SetSubtestName "GetVarCase <lowercase_reference>" 'd'
AssertEqual "lowercase" "$(DoIndirectTest GetVarCase 'lowercaseVar')"

