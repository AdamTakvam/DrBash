#!/bin/bash

source "${DRB_LIB:-.}/test.sh"
source "${DRB_LIB:-.}/logging.sh"

# config.sh reads $DRB_DATA/global.conf as soon as it's sourced and exits if it's missing.
# Point it at a throwaway one so this test doesn't depend on (or touch) the real config.
DRB_DATA="$(mktemp -d)"
trap 'rm -rf "$DRB_DATA"' EXIT
touch "$DRB_DATA/global.conf"

source "${DRB_LIB:-.}/config.sh"

SetTestName "ValidateConfigValue 'blah'"
TESTVALUE='blah'
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue string 'blah'"
TESTVALUE='blah'
TESTVALUE_TYPE=string
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue bool 'true'"
TESTVALUE='true'
TESTVALUE_TYPE=bool
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue bool '0'"
TESTVALUE='0'
TESTVALUE_TYPE=bool
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue bool 'no'"
TESTVALUE='no'
TESTVALUE_TYPE=bool
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue params '-i fart loud'"
TESTVALUE='-i fart loud'
TESTVALUE_TYPE=params
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue abs_path '/a7/b6/jhgjh'"
TESTVALUE='/a7/b6/jhgjh'
TESTVALUE_TYPE=abs_path
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue abs_path 'a7/b6/jhgjh'"
TESTVALUE='a7/b6/jhgjh'
TESTVALUE_TYPE=abs_path
_ValidateConfigValue TESTVALUE
AssertFail $?

SetTestName "ValidateConfigValue rel_path '/a7/b6/jhgjh'"
TESTVALUE='/a7/b6/jhgjh'
TESTVALUE_TYPE=rel_path
_ValidateConfigValue TESTVALUE
AssertFail $?

SetTestName "ValidateConfigValue rel_path 'a7/b6/jhgjh'"
TESTVALUE='a7/b6/jhgjh'
TESTVALUE_TYPE=rel_path
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue path '/a7/b6/jhgjh'"
TESTVALUE='/a7/b6/jhgjh'
TESTVALUE_TYPE=path
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue path 'a7/b6/jhgjh'"
TESTVALUE='a7/b6/jhgjh'
TESTVALUE_TYPE=path
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue @<the_motherfucker> '/a7/b6/jhgjh=https://myserver.edu/motherfucker'"
TESTVALUE='/a7/b6/jhgjh=https://myserver.edu/motherfucker'
TESTVALUE_TYPE=@'^(/[[:alnum:]_.-]+)+=([[:alpha:]]|\\\\[[:alnum:].-]+(\\[[:alnum:]_.-]+)*|https?://[[:alnum:].-]+(/[[:alnum:]_.-]+)*)$'
_ValidateConfigValue TESTVALUE
Assert $?

SetTestName "ValidateConfigValue @<the_motherfucker> 'C:\stupid=//clownpenis/fart'" 
TESTVALUE='C:\stupid=//clownpenis/fart'
# TESTVALUE_TYPE=<unchanged>
_ValidateConfigValue TESTVALUE
AssertFail $?

# ---------- ConfigEvalBool ----------

for v in true TRUE Yes 1; do
  SetTestName "ConfigEvalBool '$v' is true"
  ConfigEvalBool "$v"; AssertEqual 0 $?
done

for v in false FALSE No 0; do
  SetTestName "ConfigEvalBool '$v' is false"
  ConfigEvalBool "$v"; AssertEqual 1 $?
done

SetTestName "ConfigEvalBool 'maybe' is unknown"
ConfigEvalBool maybe 2>/dev/null; AssertEqual 2 $?

SetTestName "ConfigEvalBool prints nothing"
AssertEqual "" "$(ConfigEvalBool yes 2>&1)"

# ---------- ConfigSet ----------

printf '%s\n' 'DRB_LOG_COLOR=yes' 'DRB_LOG_TIMESTAMPS=no' > "$GLOBAL_CONFIG_FILE"
source "$GLOBAL_CONFIG_FILE"

SetTestName "ConfigSet replaces an existing setting"
ConfigSet LOG_COLOR no
AssertEqual "0 DRB_LOG_COLOR=no" "$? $(grep '^DRB_LOG_COLOR=' "$GLOBAL_CONFIG_FILE")"

SetTestName "ConfigSet updates the variable"
AssertEqual no "$(ConfigGet LOG_COLOR)"

SetTestName "ConfigSet appends a known setting that's missing from the file"
ConfigSet DRB_LOG_LABELS No
AssertEqual "0 DRB_LOG_LABELS=No" "$? $(grep '^DRB_LOG_LABELS=' "$GLOBAL_CONFIG_FILE")"

SetTestName "ConfigSet value with spaces and sed metacharacters survives a round trip"
ConfigSet LOG_TIMESTAMPS 'a b|c&d\e'
( source "$GLOBAL_CONFIG_FILE"; printf '%s' "$DRB_LOG_TIMESTAMPS" ) > "$DRB_DATA/out"
AssertEqual 'a b|c&d\e' "$(cat "$DRB_DATA/out")"

SetTestName "ConfigSet unknown setting returns 3"
ConfigSet LOG_BOGUS 1
AssertEqual "3 " "$? ${DRB_LOG_BOGUS}"

SetTestName "ConfigSet read-only setting returns 4 and leaves it alone"
_lib_before="$DRB_LIB"
ConfigSet LIB /nowhere
AssertEqual "4 $_lib_before" "$? $DRB_LIB"

SetTestName "ConfigSet unwritable file returns 2"
chmod a-w "$GLOBAL_CONFIG_FILE"
ConfigSet LOG_COLOR yes 2>/dev/null
_rc=$?
chmod u+w "$GLOBAL_CONFIG_FILE"
[[ $EUID == 0 ]] && _rc=2    # root can write anyway
AssertEqual 2 $_rc

SetTestName "ConfigSet TEMP doesn't touch the file"
ConfigSet TEMP LOG_COLOR maybe
AssertEqual "0 maybe DRB_LOG_COLOR=no" "$? $DRB_LOG_COLOR $(grep '^DRB_LOG_COLOR=' "$GLOBAL_CONFIG_FILE")"

SetTestName "ConfigSet TEMP works on read-only settings"
ConfigSet TEMP BIN /tmp/bin
AssertEqual "0 /tmp/bin" "$? $DRB_BIN"

exit $fail
