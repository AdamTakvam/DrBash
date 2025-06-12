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
  local d="${2:-' '}"
  
  [ -z "$1" ] && return

  while read c; do
    echo -ne "$c$d"
  done < <(fold -w1 <<< "$1")
}
