#!/bin/bash

# WORK IN PROGRESS

ScriptSummary() {
  declare script="$1"
  [ -z "$script" ] && { echo "Internal Error calling explain-this.ScriptSummary()"; return 99; }
}

Overview() {
  echo
  echo "This is a collection of admin scripts that perform various helpful functions. Some of them fix issues with software or the environment. Others help you to recover quickly from certain kinds of hardware failures. And others add functionality to your system like software is supposed to do. Now let's dig in..."

}

Overview
