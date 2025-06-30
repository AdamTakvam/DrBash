#!/bin/bash

# Unit tests for logging.sh

source "${USERLIB:-.}/logging.sh"

Raw() {
  if [ "$1" ]; then
    local -a out
    IFS=$'\n' out=($(printf "%s" "$1" | od -c))
    printf "| %s" "${out[0]}"
  fi
}

AssertEqual() {
  if [ "$1" == "$2" ]; then
    echo -e "$(ColorText GREEN 'Passed!')"
  else
    echo -e "$(ColorText LRED 'FAILED')"
    printf "\t%s\n" "Expected: ${1:-<null>} $(Raw "$1")"
    printf "\t%s\n" "Received: ${2:-<null>} $(Raw "$2")"
  fi
}

declare -i n=1
declare -r TEST_STR="This is a test"

echo -n "Test $(( n++ )): Log() with no message: "
AssertEqual "" "$(Log)"

echo -n "Test $(( n++ )): Log() write: "
AssertEqual "$TEST_STR" "$(Log "$TEST_STR")"

echo -n "Test $(( n++ )): LogError() write: "
AssertEqual "$TEST_STR" "$(LogError "$TEST_STR" 2>&1)"

echo -n "Test $(( n++ )): LogVerbose() write without verbose logging enabled: "
AssertEqual "" "$(LogVerbose "$TEST_STR")"

echo -n "Test $(( n++ )): LogVerboseError() write without verbose logging enabled: "
AssertEqual "" "$(LogVerboseError "$TEST_STR" 2>&1)"

LogEnableVerbose >/dev/null
echo -n "Test $(( n++ )): LogVerbose() write with verbose logging enabled: "
AssertEqual "$TEST_STR" "$(LogVerbose "$TEST_STR")"

echo -n "Test $(( n++ )): LogVerboseError() write with verbose logging enabled: "
AssertEqual "$TEST_STR" "$(LogVerboseError "$TEST_STR" 2>&1)"

echo -n "Test $(( n++ )): LogDebug() write without debug logging enabled: "
AssertEqual "" "$(LogDebug "$TEST_STR")"

echo -n "Test $(( n++ )): LogDebugError() write without debug logging enabled: "
AssertEqual "" "$(LogDebugError "$TEST_STR" 2>&1)"

LogEnableDebug >/dev/null
echo -n "Test $(( n++ )): LogDebug() write with debug logging enabled: "
AssertEqual "$TEST_STR" "$(LogDebug "$TEST_STR")"

echo -n "Test $(( n++ )): LogDebugError() write with debug logging enabled: "
AssertEqual "$TEST_STR" "$(LogDebugError "$TEST_STR" 2>&1)"

echo -n "Test $(( n++ )): LogLiteral() write: "
AssertEqual "$TEST_STR\n" "$(LogLiteral "$TEST_STR\n")"

echo -n "Test $(( n++ )): LogLiteral() -n write: "
AssertEqual "$TEST_STR\b" "$(LogLiteral -n "$TEST_STR\b")"

echo -n "Test $(( n++ )): Log() write from stdin: "
AssertEqual "$TEST_STR" "$(printf "%s" "$TEST_STR" | Log)"

echo -n "Test $(( n++ )): Log() -- write from stdin: "
AssertEqual "$TEST_STR" "$(printf "%s" "$TEST_STR" | Log --)"
