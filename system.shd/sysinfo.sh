#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
Require inxi

inxi -SMGxxx
