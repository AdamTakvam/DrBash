#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/general.sh"
Require inxi

inxi -SMGxxx
