[[ -n "$__arrays" ]] && return
__arrays=1

source "${USERLIB:-$HOME/lib}/logging.sh"

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
    echo "${tempStr%$delim*}"
  else
    echo "${tempStr::-1}"
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

# Sorts the specified array
# + $1 = The namne of the array variable you want to have sorted.
# - $1 = Your array will be sorted in-place. No fancy tricks needed to reassign it.
SortArray() {
  [ -z "$1" ] && return 1

  declare -n array="$1"
  IFS=$'\n' array=($(sort <<< "${array[*]}"))
  # printf "[%s]\n" "${array[@]}"
  # echo "Your sorted array = ${array[@]}"
}
