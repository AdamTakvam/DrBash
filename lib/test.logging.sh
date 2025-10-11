#!/bin/bash

# Unit tests for logging.sh

source "${DRB_LIB:-.}/cli.sh"
source "${DRB_LIB:-.}/logging.sh"
source "${DRB_LIB:-.}/test.sh"

declare -r TEST_STR='This is a test'

SetTestName "Log()"
AssertEqual "" "$(Log)"

SetTestName "Log('$TEST_STR')"
AssertEqual "$TEST_STR" "$(Log "$TEST_STR")"

declare -r TEST_HYPHENS='-----------'
SetTestName "Log($TEST_HYPHENS)"
AssertEqual "$TEST_HYPHENS" "$(Log "$TEST_HYPHENS")"

declare ML_TEST_STR1='This
is
a
test'
SetTestName "Log(<natural multiline input>)"
AssertEqual "$ML_TEST_STR1" "$(Log "$ML_TEST_STR1")"

ML_TEST_STR2="This\nis\na\ntest"
SetTestName "Log(<symbolic multiline input>)"
AssertEqual "$ML_TEST_STR1" "$(Log "$ML_TEST_STR1")"

SetTestName "Log(-c=WHITE -n $TEST_STR)"
AssertSubstring "$TEST_STR" "$(Log -c=WHITE -n "$TEST_STR")"

SetTestName "LogError('$TEST_STR')"
AssertSubstring "$TEST_STR" "$(LogError "$TEST_STR" 2>&1)"

SetTestName "LogVerbose('$TEST_STR') verbose logging disabled"
AssertEqual "" "$(LogVerbose "$TEST_STR")"

SetTestName "LogVerboseError('$TEST_STR') verbose logging disabled"
AssertEqual "" "$(LogVerboseError "$TEST_STR" 2>&1)"

LogEnableVerbose >/dev/null
SetTestName "LogVerbose('$TEST_STR') verbose logging enabled"
AssertSubstring "$TEST_STR" "$(LogVerbose "$TEST_STR")"

SetTestName "LogVerboseError('$TEST_STR') verbose logging enabled"
AssertSubstring "$TEST_STR" "$(LogVerboseError "$TEST_STR" 2>&1)"

SetTestName "LogDebug('$TEST_STR') debug logging disabled"
AssertEqual "" "$(LogDebug "$TEST_STR")"

SetTestName "LogDebugError('$TEST_STR') debug logging disabled"
AssertEqual "" "$(LogDebugError "$TEST_STR" 2>&1)"

LogEnableDebug >/dev/null
SetTestName "LogDebug('$TEST_STR') debug logging enabled"
AssertSubstring "$TEST_STR" "$(LogDebug "$TEST_STR")"

SetTestName "LogDebugError('$TEST_STR') debug logging enabled"
AssertSubstring "$TEST_STR" "$(LogDebugError "$TEST_STR" 2>&1)"

SetTestName "LogLiteral('$TEST_STR')"
AssertEqual "$TEST_STR\n" "$(LogLiteral "$TEST_STR\n")"

SetTestName "LogLiteral(-n '$TEST_STR')"
AssertEqual "$TEST_STR\b" "$(LogLiteral -n "$TEST_STR\b")"

SetTestName "Log(--) ['$TEST_STR' from stdin]"
AssertEqual "$TEST_STR" "$(printf "%s" "$TEST_STR" | Log --)"

SetTestName "LogHeader('$TEST_STR')"
AssertSubstring "$TEST_STR" "$(LogHeader "$TEST_STR")"

SetTestName "Header('$TEST_STR')"
AssertSubstring "$TEST_STR" "$(Log "$(LogHeader "$TEST_STR")")"

TABLE_TEST="log\ttable\ttest"
SetSubtestName "LogTable('$TABLE_TEST') 'log'" 'a'
AssertSubstring "log" "$(LogTable "$TABLE_TEST")"

SetSubtestName "LogTable('$TABLE_TEST') 'table'" 'b'
AssertSubstring "table" "$(LogTable "$TABLE_TEST")"

SetSubtestName "LogTable('$TABLE_TEST') 'test'" 'c'
AssertSubstring "test" "$(LogTable "$TABLE_TEST")"

SetTestName "LogQuote('$TEST_STR')"
AssertSubstring "$TEST_STR" "$(LogQuote "$TEST_STR")"

exit $fail
