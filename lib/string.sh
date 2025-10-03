[[ -n $__STRING ]] && return 0
__STRING=1

declare -r DEFAULT_IFS=$' \t\n'

ResetIFS() {
  declare -g IFS="$DEFAULT_IFS"
}

IsIFSDefault() {
  [[ "$IFS" == "$DEFAULT_IFS" ]] \
    && return 0 \
    || return 1
}

IsIFSaSpace() {
  [[ "${IFS::1}" == ' ' ]] \
    && return 0 \
    || return 1
}

RegexEscape() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\]/\\&/g'
}

# stdin -> single-line base64 (no wraps). Trailing newline is fine;
# command substitution will strip it when you capture to a var.
b64_enc() { base64 -w 0; }

# stdin -> decoded bytes
b64_dec() { base64 -d; }

### Examples:
# enc=$(printf '%s' "$payload" | b64_enc)
# decoded=$(printf '%s' "$enc" | b64_dec)

# Splits the given string into an array on the specified character.
#   Avoids accidental global IFS setting.
#   Avoids accidental filename parameter expansion.
# + $1 = The name of an array variable to hold the result.
# + $2 = The delimiter character(s)
# + $3+ = The string to split.
Split() {
  [[ -z "$2" ]] && return 1

  local -n _out="$1"; shift
  local delim="$1"; shift

  [[ "$delim" == '' ]] \
    && ResetIFS \
    || local IFS="$delim"

  set -f          # Prevents * from expanding to all files in $PWD
#  _out=($@)

  if IsIFSaSpace; then
    _out=("$1"); shift
    for p in "$@"; do
      _out+=("$p")
    done
  else
    _out=($1); shift
    for p in $@; do
      _out+=("$p")
    done
  fi

  set +f
  return 0
}

# + $1 = The string to be searched
# + $2 = the substring or extended regular expression to search for
# - Returns an integer indicating the number of times the substring matched.
StringContains() {
  local -r tgtStr="$1"
  local -r findStr="$2"
  
  [ -z "$tgtStr" ] && return 0
  [ -z "$findStr" ] && return 0

  tmpStr="$(echo "$tgtStr" | sed -E "s/$findStr//g")"  # Remove all instances of findStr from tgtStr
  local -i diff=$(( ${#tgtStr} - ${#tmpStr} ))         # How many chars were removed?
  return $(( $diff / ${#findStr} ))                    # That equals how many instances of findStr?
}
export -f StringContains

# Returns the index of the first occurence of $1 in $2
# + $1 = The single character you want to find
# + $2 = The string to search
# - Returns the 0-based index of the char within the string or -1 if not found.
GetFirstIndexOf() {
  local -r char="$1"
  local -r targetStr="$2"

  if [ ${#char} == 1 ]; then
    local prefix=${targetStr#${char}*}
    return ${#prefix}
  fi

  return -1
}

# Returns the index of the last occurence of $1 in $2
# + $1 = The single character you want to find
# + $2 = The string to search
# - Returns the 0-based index of the char within the string or -1 if not found.
GetLastIndexOf() {
  local -r char="$1"
  local -r targetStr="$2"

  if [ ${#char} == 1 ]; then
    local prefix=${targetStr%${char}*}
    return ${#prefix}
  fi

  return -1
}

# Breaks a string into a list of characters
# + $1 = The string you want to break up into characters
# + $2 = (opt) The desired intra-character delimiter (default=space) 
# - stdout = the input string as one character per line
GetChars() {
  local str="$1"
  local d="${2:- }"

  [ -z "$str" ] && return

  while IFS= read -r -n1 c; do
    printf "%s%s" "$c" "$d"
  done <<< "$str"
}
