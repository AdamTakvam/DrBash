#!/usr/bin/env bash
# Usage: ./docgen-logging.sh ./lib/logging.sh > LOGGING.md
set -Eeuo pipefail

f="${1:?path to logging.sh}"

awk -v FILE="$f" '
function trim(s){ sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); return s }
function split_doc(d,   i,n,lines,first,rest) {
  n = split(d, lines, /\n/)
  first=""; rest=""
  for (i=1;i<=n;i++) {
    if (trim(lines[i]) != "") { first = trim(lines[i]); break }
  }
  # collect remainder (skip leading empties and the first summary line)
  skip = 1
  seenFirst=0
  for (i=1;i<=n;i++) {
    line = lines[i]
    # skip leading blank lines before the summary
    if (!seenFirst) {
      if (trim(line) == "") continue
      seenFirst=1
      # this line is the summary; skip it from body
      continue
    } else {
      rest = rest line "\n"
    }
  }
  return first "\t" rest
}
function flush(){
  if(fn){
    # derive summary + body
    sb = split_doc(doc)
    split(sb, parts, /\t/)
    summary = parts[1]
    body = parts[2]
    priv = (fn ~ /^_/ ? " (private)" : "")
    if (summary != "") {
      print "### " fn priv " — " summary "\n"
    } else {
      print "### " fn priv "\n"
    }
    if (trim(body) != "") { print body }
    else if (summary == "") { print "_No doc block above function._\n" }
  }
  doc=""; fn=""
}
BEGIN{
  print "# DrBash `logging.sh` — Function Reference\n"
  print "_Source: " FILE "_\n"
}
{
  # accumulate leading comment lines (doc block)
  if ($0 ~ /^[[:space:]]*#/) {
    sub(/^[[:space:]]*#[ ]?/, "", $0)   # strip first "# " cleanly
    doc = doc $0 "\n"
    next
  }

  # tolerate blank lines inside the doc block
  if ($0 ~ /^[[:space:]]*$/) { doc = doc "\n"; next }

  # function start?
  if ($0 ~ /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/) {
    flush()
    match($0, /^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{/, m)
    fn = m[1]
    doc = doc "\n"
    next
  }

  # any other non-comment line clears pre-collected orphan doc
  if (doc != "" && fn == "") { doc="" }
}
END{ flush() }' "$f"

