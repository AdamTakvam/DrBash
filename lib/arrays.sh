[[ -n "$__arrays" ]] && return
__arrays=1

source "${DRB_LIB:-/usr/local/lib}/logging.sh"
source "${DRB_LIB:-/usr/local/lib}/cli.sh"
source "${DRB_LIB:-/usr/local/lib}/string.sh"

# Determines whether the given array contrains any useful data
# + $1 = The name of a one-dimensional array declared in the caller's scope.
# - retVal = 0 if array contains no data
IsEmptyArray() {
  [[ -z "$1" ]] && return 99

  local -n _array="$1"

  # Appallingly simple implementation, yet difficult to remember when you need it!
  [[ -z "${_array[@]}" ]] && return 0 || return 1
}

# Edits each element in the given array as indicated
# Usage: EditArray [OPTIONS] ARRAY_NAME
# OPTIONS:
#       -p=<string>     Add the prefix <string> to every element of ARRAY_NAME
#       -s=<string>     Add the suffix <string> to every element of ARRAY_NAME
#       -rm=<regex>     Get all occurences of text matching <regex> from every element of ARRAY_NAME
#       -rr=<repl_exp>  Replace all previously matched text with <repl_exp>
# Notes:
#       * If -rm is specified without -rr, then all matching text will be deleted
#       * If -rr is specified without -rm, then it is ignored
#       * <regex> is an extended regular expression applied with 'sed -E'
#       * Therefore -rr may include back-references (e.g. -rm='(.*)' -rr='\1')
# ARRAY_NAME: Literally just the name of your array variable.
EditArray() {
  unset array prefix suffix match_exp repl_expr  # Hey, you never know!
  local -n array

  for p in $@; do
    pv="${p#*=}"
    p="${p%%=*}"
    
    case $p in
      -p)
        prefix="$pv" ;;
      -s)
        suffix="$pv" ;;
      -rm)
        match_exp="$pv" ;;
      -rr)
        repl_expr="$pv" ;;
      *)
        [ -z "$array" ] && array="$p" ;;
    esac
  done
  
  for (( i=0; i<${#array[@]}; i++ )); do
    if [ "$match_exp" ]; then
      array[$i]="$(sed -E "s/$match_exp/$repl_exp/g")"
    fi
    array[$i]="${prefix}${array[$i]}${suffix}"
  done
  
}

# Prints the given array elements as a space-delimited string.
# + $1, $2 = (optional) formatting options:
#               -q          Enclose each array item in quotes
#               -d=<char>   Add <char> between each element
#               -d^         Include delimiter before first element
#               -d$         Include delimiter after last element
#               -ds         Add a space before <char> delimiter
#               -dS         Add a space after <char> delimiter
#               -de         Add a newline after each element
#               -s          Sort the elements in the array
# + $3 ... = The name of the array as defined in the caller's scope. 
#             That's right; just the variable name, not the array itself. We got it. Don't worry!
# - stdout = The serialized version of your array
SerializeArray() {
  local -i quotes=0 crlf=0 sortArray=0 delim_pre=0 delim_post=0
  local -n array        # "But the manpage says -n can't be used with arrays!"
  local delim=''        # FALSE! It can't be used to declare an array (e.g. declare -a -n)

  for p in "$@"; do
    pv="${p#*=}"         # "$(echo "$p" | cut -d= -f2)"
    p="${p%%=*}"         # "$(echo "$p" | cut -d= -f1)"

    case "$p" in
      -q)
        quotes=1 ;;
      -d^)
        delim_pre=1 ;;
      -d$)
        delim_post=1 ;;
      -ds)
        d1=' ' ;;
      -dS)
        d3=' ' ;;
      -d)
        d2="$pv" ;;
      -de | -e)
        crlf=1 ;;
      -s)
        sortArray=1 ;;
      *)
        [ -z "$array" ] && array="$p" ;;
    esac
  done

  [ ${#array[@]} == 0 ] && return 1

  if [ $sortArray == 1 ]; then
    SortArray "array"
  fi

  local tempStr=""
  if [ "$d2" ]; then
    delim=$d1$d2$d3
    [ $delim_pre == 1 ] && tempStr="$d2$d3"
  fi

  for e in "${array[@]}"; do
    [ $quotes == 1 ] && tempStr+=\"
    tempStr+="$e"
    [ $quotes == 1 ] && tempStr+=\"
    [ "$delim" != '' ] && tempStr+="$delim"
    [ $crlf == 1 ] && tempStr+='
' 
    [ "$delim" == '' ] && [ $crlf == 0 ] && tempStr+=' '
  done
  
  if [ $delim_post == 0 ] && [ "$delim" != '' ]; then
    printf "%s\n" "${tempStr%$delim*}"
  else
    printf "%s\n" "${tempStr::-1}"
  fi
}

# Parses a string into array elements and populates the specified array in the caller's scope.
# + $1, $2 = (optional) formatting options:
#               -a          The name of an empty array defined in the caller's scope.
#                           If not specified, array will be output to stdout as space-delmited elements
#               -q          Enclose each array item in quotes
#               -d=<char>   Array items are delimited by <char> between each element
#               -de         Each element is on its own line
#               -dt         Each element is separated by a tab character 
#               -ds         Each element is separated by a space character before the delimiter (or space is the delimiter)
#               -dS         Each element is separated by a space character after the delimiter
#           Note: Parameters, -d, -
# + $3    = The serialized array 
#DeserializeArray() {
#  local -i quotes=0 pre_space=0 post_space=0
#  local delim=' ' arrayStr=''
#
#  for p in "$@"; do
#    pv="${p#*=}"         # "$(echo "$p" | cut -d= -f2)"
#    p="${p%%=*}"         # "$(echo "$p" | cut -d= -f1)"
#
#    case "$p" in
#      -a)
#        arrayName="$pv" ;;
#      -q)
#        quotes=1 ;;
#      -d)
#        delim="$pv" ;;
#      -de)
#        delim=$'\n' ;;
#      -dt)
#        delim=$'\t' ;;
#      -ds)
#        pre_space=1 ;;
#      -dS)
#        post_space=1 ;;
#      *)
#        arrayStr+="$p " ;;
#    esac
#  done
#
#  if [ -z "$arrayName" ]; then
#    LogError "No array specified to deserialize the data into!"
#    return 1
#  fi
#
#  if [ -z "$arrayStr" ]; then
#    LogError "No array data specified to deserialize!"
#    return 2
#  fi
#
#  local -n array="$arrayName"
#
## We're looping through $arrayStr and pulling out elements at each instance of $delim
## This similar to shifting input parameters except we're doing it with a single string
## When there are no more instances of $delim in $arrayStr, Bash will simply return the entire string.
## Therefore, we know that we have parsed out all of the elements when $element is equal to $arrayStr
#  local element=''
#  while [ "$element" != "$arrayStr" ]; do                     # Do this until you run out of delimiters
#    if [ "$post_space" == 1 ] && [ "$element" != '' ]; then   # If input string has a space after the delimiter and this is not the first element
#      arrayStr="${arrayStr:1}"                                #  then remove the first char of input (the one immediately following delim.)
#    fi
#
#    # ${element}${delim}${arrayStr}
#    element="${arrayStr#*$delim}"                             # Get chars from 0 to first instance of $delim
#    arrayStr="${arrayStr%%${delim}*}"                         # Get all chars after the first instance of $delim
#    
#    if [ "$pre_space" == 1 ] && [ "$element" != "$arrayStr" ]; then # If input string contains a space before delim and this isn't the last element
#      element="${element:: -1}"                                     #  then nip off the last char of the current element.
#    fi
#
#    if [ $quotes == 1 ] || [ "$element" == '' ] && [ ${element:1} != "\"" ]; then
#      element="\"$element\""
#    fi
#
#    array+=($element)
#  done
#}

# Sorts the specified array using string comparison
#   It sorts alphabetically, but you won't like what it does with integers!
#   If you want to sort by integers, use SortIntArray()
# + $1 = The name of the array variable you want to have sorted.
# - $1 = Your array will be sorted in-place. No fancy tricks needed to reassign it.
SortArray() {
  [[ -z "$1" ]] && return 99

  local -n array="$1"
  IFS=$'\n' array=($(printf "%s\n" "${array[@]}" | sort))
}

# Sorts the specified array using full integer comparison
#   e.g. 2, 1, 10 gets sorted as 1, 2, 10 not 1, 10, 2
# + $1 = The name of the array variable you want to have sorted.
# - $1 = Your array will be sorted in-place. No fancy tricks needed to reassign it.
SortIntArray() {
  [[ -z "$1" ]] && return 99

  local -n array="$1"
  IFS=$'\n' array=($(printf "%s\n" "${array[@]}" | sort -n))
}


# Adds the specified item to the specified sorted array
# + $1 = The name of the array
# + $2 = The item to be added
# + $3 = 1 if you want to be able to add duplicate items
# - retVal =  0 if item was added successfully
#             1 if item already exists in the array
SortedArrayAdd() {
  [[ -z "$1" ]] || [[ -z "$2" ]] && return 99

  local -n _array="$1"
  local _newItem="$2"
  local -i _dupes=$3

  if [[ $_dupes != 1 ]]; then
    ArrayContains "$1" "$_newItem" && return 1
  fi

  $_array+="$_newItem"
  IFS=$'\n' _array=($(printf "%s\n" "${_array[@]}" | sort))
}

# Determines whether the given array contains at least one element matching the specified value or expression.
#   If a match value is specified, the search will terminate after the first match.
#   If a match expression is specified, all matches will be returned (one per line).
# Tip: To match an element exactly, anchor the value between ^ and $ (e.g. ^exact value$).
# + $1 =  The name of an array to search.
# + $2 =  MATCH TERM
#           -v=<value> - The literal value to search for (exact matches only).
# +         -x=<regex> - The regular expression to search for. [default]
# + $3 =  OPTIONS
#           -i - Case-insensitive comparison
#           -I - Exact comparison [default]
#           -q - Suppress match result echo
# - retVal = 0 if value is found
ArrayContains() {
  [[ -z "$1" ]] || [[ -z "$2" ]] && return 99

  local -n _array="$1"; shift
  local _match="$1"; shift
  local _opt=""

  # Allow options to come in as a blob or separated out
  # We're just going to make them into a blob
  for p in "$@"; do
    _opt+="$(GetParamName "$p")"
  done

  # Literal or expr search?
  local -i literal=0

  local match_type="$(GetParamName "$_match")"
  local match_value="$(GetParamValue "$_match")"

  [[ "$match_type" == 'v' ]] && match_value="^$(RegexEscape "$match_value")$"  # Dress the literal as a regex for logical simplicity

  # Walk the array elements and inspect each one
  local -i found=0

  for e in "${_array[@]}"; do
    if [[ "$_opt" == *i* ]]; then                               # case-insensitive match
      if [[ "${e,,}" =~ ${match_value,,} ]]; then               # match_value as value or expression
        [[ "$_opt" == *q* ]] || printf "%s\n" "$e"              # output the matched value
        found=1                                                 # Set the found flag
        [[ "$match_type" == 'v' ]] && return 0                  # If this is a literal match, we're done here!
      fi
    else                                                        # case-sensitive match
#      if [[ "$(printf "%s" "$e" | grep "$
      if [[ "$e" =~ $match_value ]]; then                       # match_value as value or expression
         [[ "$_opt" == *q* ]] || printf "%s\n" "$e"             # output the matched value
        found=1                                                 # Set the found flag
        [[ "$match_type" == 'v' ]] && return 0                  # If this is a literal match, we're done here!
      fi
    fi
  done

  [[ "$found" == 1 ]] && return 0 || return 1
}
