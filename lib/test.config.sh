#!/bin/bash

source "test.sh"
source "./config.sh"

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

