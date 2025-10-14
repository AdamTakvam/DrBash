#!/usr/bin/env bash
# Usage: ./docgen-lib.sh ./lib/logging.sh > LOGGING.md
set -Eeuo pipefail
f="${1:?path to a Bash source file}"

awk -v FILE="$f" '
function strip_hash_line(s) { sub(/^[[:space:]]*#[ ]?/, "", s); return s }

BEGIN{
  print "# Function Reference"
  print "_Source: " FILE "_\n"
  in_func = 0; brace_depth = 0
  doc_len = 0
}

# Collect ONLY the contiguous comment block *immediately above* a function
/^[[:space:]]*#/ {
  if (in_func) next                   # ignore comments inside functions
  doc[++doc_len] = strip_hash_line($0)
  next
}

# Blank lines are allowed inside the pending doc block
/^[[:space:]]*$/ {
  if (in_func) next
  if (doc_len > 0) doc[++doc_len] = ""
  next
}

# Any other non-comment/blank line BEFORE a function clears the pending doc
{
  if (!in_func && doc_len > 0) {
    # We saw code, so that comment block wasn’t directly above a function → discard.
    for (i in doc) delete doc[i]; doc_len = 0
  }

  # Detect function start (common Bash styles)
  if (match($0, /^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{/, m) ||
      match($0, /^[[:space:]]*function[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{/, m) ||
      match($0, /^[[:space:]]*function[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\{/, m)) {

    fn = m[1]
    priv = (fn ~ /^_/ ? " (private)" : "")
    printf("### %s%s\n\n", fn, priv)

    # Emit the doc block we just collected (which sat immediately above)
    if (doc_len > 0) {
      for (i=1; i<=doc_len; i++) print doc[i]
      print ""
    } else {
      print "_No doc block above function._\n"
    }

    # Reset the doc buffer for the next function
    for (i in doc) delete doc[i]; doc_len = 0

    # Enter function to ignore inner comments; track braces without mutating $0
    in_func = 1
    line = $0
    opens  = gsub(/\{/, "", line)
    closes = gsub(/\}/, "", line)
    brace_depth = opens - closes
    next
  }

  # If we are inside a function, track when we leave it (ignore inner comments)
  if (in_func) {
    line = $0
    opens  = gsub(/\{/, "", line)
    closes = gsub(/\}/, "", line)
    brace_depth += opens - closes
    if (brace_depth <= 0) { in_func = 0; brace_depth = 0 }
    next
  }

  # Otherwise: normal code outside functions → nothing else to do.
}
' "$f"

