#!/bin/bash

# Unit tests for logging.sh

source "${USERLIB:-.}/logging.sh"

EchoErrorOutput() {
#  cmd="$1"
#  [ -z "$cmd" ] && return 1

#  [ "$2" ] && cmd+=" $@"
  cmd="$@"
  2>&1 1>/dev/null env $cmd
}

declare -i n=1
declare -r TEST_STR="This is a test"

echo -n "Test $(( n++ )): Log() write: "
exp_out="$TEST_STR"
act_out="$(Log "$TEST_STR")"
[ "$exp_out" == "$act_out" ] && echo "PASSED" \
  || echo -e "FAILED\nExpected: ${exp_out}\nReceived: ${act_out}\n"

echo -n "Test $(( n++ )): LogError() write: "
exp_out="$TEST_STR"
act_out="$(EchoErrorOutput LogError "$TEST_STR")"
[ "$exp_out" == "$act_out" ] && echo "PASSED" \
  || echo -e "FAILED\nExpected: ${exp_out}\nReceived: ${act_out}\n"

echo -n "Test $(( n++ )): LogVerbose() write without verbose logging enabled: "
exp_out=""
act_out="$(LogVerbose "$TEST_STR")"
[ "$exp_out" == "$act_out" ] && echo "PASSED" \
  || echo -e "FAILED\nExpected: ${exp_out}\nReceived: ${act_out}\n"

echo -n "Test $(( n++ )): LogVerboseError() write without verbose logging enabled: "
exp_out=""
act_out="$(LogVerboseError "$TEST_STR")"
[ "$exp_out" == "$act_out" ] && echo "PASSED" \
  || echo -e "FAILED\nExpected: ${exp_out}\nReceived: ${act_out}\n"

LogEnableVerbose
echo -n "Test $(( n++ )): LogVerbose() write with verbose logging enabled: "
exp_out="$TEST_STR"
act_out="$(LogVerbose "$TEST_STR")"
[ "$exp_out" == "$act_out" ] && echo "PASSED" \
  || echo -e "FAILED\nExpected: ${exp_out}\nReceived: ${act_out}\n"

echo -n "Test $(( n++ )): LogVerboseError() write with verbose logging enabled: "
exp_out="$TEST_STR"
act_out="$(LogVerboseError "$TEST_STR")"
[ "$exp_out" == "$act_out" ] && echo "PASSED" \
  || echo -e "FAILED\nExpected: ${exp_out}\nReceived: ${act_out}\n"
