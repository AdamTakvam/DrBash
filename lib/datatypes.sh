[[ ${__datatypes-} == 1 ]] && return 1
declare -g __datatypes=1

declare -ag DATATYPES=('string' 'integer' 'array' 'dictionary')

# Determines the current data type of the specified variable
# All possible values are enumerated in DATATYPES
# + $1 = Variable name
# - stdout = The friendly name of the type (only if stdout is redirected)
# - retVal = The numerical index into DATATYPES.
# This command cannot fail
GetVarType() {
  [[ -z "$1" ]] && return 99
  local _variableName="$1"
  local -a decl=($(declare -p "$_variableName"))
  local -i typeIndex=0
  local attrs="${decl[1]}"
  case "$attrs" in
    --)
      typeIndex=0 ;;
    *i*)
      typeIndex=1 ;;
    *a*)
      typeIndex=2 ;;
    *A*)
      typeIndex=3 ;;
    *n*)
      # If variable is passed by reference, 
      #   then we have to unwrap until we get to the real variable behind all of the pointers.
      local varname="${decl[2]}"
      varname="$(echo "$varname" | grep -Po '(?<=")[^"]+(?=")')"
      GetVarType "$varname"
      return $? ;;
  esac
  
  IsRedirected && printf '%s' "${DATATYPES[$typeIndex]}"
  return $typeIndex
}

declare -ag SCOPES=('global' 'function' 'exported' )

# Determines the current scope of the specified variable
# All possible values are enumerated in SCOPES
# + $1 = Variable name
# - stdout = The friendly name of the scope (only if stdout is redirected)
# - retVal = The numerical index into SCOPES.
# This command cannot fail
GetVarScope() {
  [[ -z "$1" ]] && return 99
  local _variableName="$1"
  local -a decl=($(declare -p "$_variableName"))
  local -i scopeIndex=0
  local attrs="${decl[1]}"
  case "$attrs" in
    --)
      scopeIndex=0 ;;
    *g*)
      scopeIndex=0 ;;
    *x*)
      scopeIndex=2 ;;
    *n*)
      local varname="${decl[2]}"
      varname="$(echo "$varname" | grep -Po '(?<=")[^"]+(?=")')"
      GetVarScope "$varname"
      return $? ;;
  esac
  
  IsRedirected && printf '%s' "${SCOPES[$scopeIndex]}"
  return $scopeIndex
}

declare -ag ACCESS=('readwrite' 'read')

# Determines the current access modifier of the specified variable
# All possible values are enumerated in ACCESS
# + $1 = Variable name
# - stdout = The friendly name of the access modifier (only if stdout is redirected)
# - retVal = The numerical index into ACCESS.
# This command cannot fail
GetVarAccess() {
  [[ -z "$1" ]] && return 99
  local _variableName=$1
  local -a decl=($(declare -p "$_variableName"))
  local -i accessIndex=0
  local attrs="${decl[1]}"
  
  case "$attrs" in
    *r*)
      accessIndex=1 ;;
    *n*)
      local varname="${decl[2]}"
      varname="$(echo "$varname" | grep -Po '(?<=")[^"]+(?=")')"
      GetVarAccess "$varname"
      return $? ;;
  esac

  IsRedirected && printf '%s' "${ACCESS[$accessIndex]}"
  return $accessIndex
}

declare -ag CASING=('mixedcase' 'lowercase' 'uppercase')

# Determines the current case of the specified variable
# All possible case are enumerated in CASING
# + $1 = Variable name
# - stdout = The friendly name of the case (only if stdout is redirected)
# - retVal = The numerical index into CASING of the type.
# This command cannot fail
GetVarCase() {
  [[ -z "$1" ]] && return 99
  local _variableName="$1"
  local -a decl=($(declare -p "$_variableName"))
  local -i caseIndex=0
  local attrs="${decl[1]}"
  case "$attrs" in
    *l*)
      caseIndex=1 ;;
    *u*)
      caseIndex=2 ;;
    *n*)
      local varname="${decl[2]}"
      varname="$(echo "$varname" | grep -Po '(?<=")[^"]+(?=")')"
      GetVarCase "$varname"
      return $? ;;
  esac
  
  IsRedirected && printf '%s' "${CASING[$caseIndex]}"
  return $caseIndex
}

