#!/bin/bash

cMsg="${1:-Changed code}"
git add . \
  && git commit -m "$cMsg" \
  && git push
