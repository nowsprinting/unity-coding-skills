#!/usr/bin/env bash
# Extract [Category("VisualVerification")] test results from TestResults.xml.
#
# TestResults.xml under Application.persistentDataPath is written by the
# com.unity.test-framework.performance package (Editor.RunFinished), not by
# Unity Test Framework itself — UTF only writes a result XML in CLI/batchmode
# runs, to <project-root>/TestResults-<ticks>.xml. So when the performance
# package is not installed, this script finds nothing; fall back to Editor.log
# (see run-tests/SKILL.md -> Visual Verification).
#
# Not Python: native Windows guarantees no Python, only Git Bash (with awk).
# Not line-based grep/awk: a class-scoped [Category] is recorded on the
# ancestor <test-suite type="TestFixture"> element (not on the <test-case>
# itself), a single test can record multiple "Screenshot" properties,
# property values are XML-entity-escaped, attribute values may contain ">",
# and CDATA in <output>/<message> may contain "<". So the awk below
# tokenizes on "<" and parses attributes quote-aware.
set -euo pipefail

readonly EXIT_ERROR=1
readonly EXIT_USAGE=2
readonly EXIT_NO_RESULTS_XML=3
readonly EXIT_PARSE=4

usage_error() {
  echo "Usage: $(basename "$0") <unity-project-root> [test-results-xml]" >&2
  echo "  <unity-project-root> is only read when [test-results-xml] is omitted" >&2
  echo "  (it is passed to get_persistent_data_path.sh to locate the default file)." >&2
  echo "Error: $1" >&2
  exit "$EXIT_USAGE"
}

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
  usage_error "expected 1 or 2 arguments"
fi

if [ $# -eq 2 ]; then
  results_xml="$2"
else
  helper="$(cd "$(dirname "$0")" && pwd)/get_persistent_data_path.sh"
  helper_stderr=$(mktemp)
  trap 'rm -f "$helper_stderr"' EXIT
  if ! persistent_data_path=$(bash "$helper" "$1" 2>"$helper_stderr"); then
    echo "Error: $(basename "$helper") failed: $(cat "$helper_stderr")" >&2
    exit "$EXIT_ERROR"
  fi
  results_xml="$persistent_data_path/TestResults.xml"
fi

if [ ! -f "$results_xml" ]; then
  echo "Error: no TestResults.xml found at $results_xml" >&2
  echo "This file is written by the com.unity.test-framework.performance package, not by Unity Test Framework itself. If that package is not installed in this project, fall back to Editor.log (see run-tests SKILL.md -> Visual Verification)." >&2
  exit "$EXIT_NO_RESULTS_XML"
fi

# LC_ALL=C makes awk byte-oriented, so sprintf("%c") in chr() emits raw UTF-8 bytes in gawk, mawk, and BSD awk alike.
status=0
out=$(LC_ALL=C awk -v CATEGORY="VisualVerification" '
function hexval(h,   i, v) {
  v = 0
  for (i = 1; i <= length(h); i++) v = v * 16 + index("0123456789abcdef", tolower(substr(h, i, 1))) - 1
  return v
}
function chr(n) {
  if (n < 128) return sprintf("%c", n)
  if (n < 2048) return sprintf("%c%c", 192 + int(n / 64), 128 + n % 64)
  if (n < 65536) return sprintf("%c%c%c", 224 + int(n / 4096), 128 + int(n / 64) % 64, 128 + n % 64)
  return sprintf("%c%c%c%c", 240 + int(n / 262144), 128 + int(n / 4096) % 64, 128 + int(n / 64) % 64, 128 + n % 64)
}
function unescape(s,   out, i, j, ent) {
  gsub(/\r\n/, "\n", s)
  gsub(/[\t\n\r]/, " ", s)
  out = ""
  while ((i = index(s, "&")) > 0) {
    out = out substr(s, 1, i - 1)
    s = substr(s, i)
    j = index(s, ";")
    if (j == 0) break
    ent = substr(s, 2, j - 2)
    if (ent == "lt") out = out "<"
    else if (ent == "gt") out = out ">"
    else if (ent == "quot") out = out "\""
    else if (ent == "apos") out = out "\047"
    else if (ent == "amp") out = out "&"
    else if (ent ~ /^#[xX][0-9a-fA-F]+$/) out = out chr(hexval(substr(ent, 3)))
    else if (ent ~ /^#[0-9]+$/) out = out chr(substr(ent, 2) + 0)
    else out = out "&" ent ";"
    s = substr(s, j + 1)
  }
  return out s
}
function is_space(ch) { return ch == " " || ch == "\t" || ch == "\n" || ch == "\r" }
function open_el(name,   d, pn, pv) {
  stack[++sp] = name
  if (!root_seen) { root_seen = 1; start = A["start-time"] }
  if (name == "test-suite") {
    depth++; suite_sp[depth] = sp; suite_hit[depth] = 0
  } else if (name == "test-case" && sp - 1 == (depth ? suite_sp[depth] : 1)) {
    in_case = 1; case_sp = sp
    cfull = A["fullname"]; cres = A["result"]
    case_hit = 0; cshots = 0; cdesc = "(none)"; has_desc = 0
  } else if (name == "property" && sp >= 3 && stack[sp - 1] == "properties") {
    pn = A["name"]; pv = A["value"]
    if (in_case && case_sp == sp - 2) {
      if (pn == "Category" && pv == CATEGORY) case_hit = 1
      else if (pn == "Screenshot") cshot[++cshots] = pv
      else if (pn == "Description" && !has_desc) { cdesc = pv; has_desc = 1 }
    } else if (depth && suite_sp[depth] == sp - 2) {
      if (pn == "Category" && pv == CATEGORY) suite_hit[depth] = 1
    }
  }
}
function close_el(name,   d, hit, k) {
  if (sp < 1 || stack[sp] != name) { malformed = 1; return }
  if (name == "test-case" && in_case && case_sp == sp) {
    in_case = 0
    names = names (ncases ? ", " : "") cfull
    ncases++
    hit = case_hit
    for (d = 1; d <= depth; d++) if (suite_hit[d]) hit = 1
    if (hit) {
      nmatch++
      mfull[nmatch] = cfull; mres[nmatch] = cres; mdesc[nmatch] = cdesc; mshots[nmatch] = cshots
      for (k = 1; k <= cshots; k++) mshot[nmatch, k] = cshot[k]
    }
  } else if (name == "test-suite") {
    depth--
  }
  sp--
}
function parse_tag(r,   n, i, j, ch, name, an, q, selfclose) {
  n = length(r); i = 1
  while (i <= n) { ch = substr(r, i, 1); if (is_space(ch) || ch == "/" || ch == ">") break; i++ }
  name = substr(r, 1, i - 1)
  split("", A)
  selfclose = 0
  while (1) {
    if (i > n) { malformed = 1; return }
    ch = substr(r, i, 1)
    if (ch == ">") break
    if (ch == "/") { selfclose = 1; i++; continue }
    if (is_space(ch)) { i++; continue }
    j = i
    while (i <= n && substr(r, i, 1) != "=" && !is_space(substr(r, i, 1))) i++
    an = substr(r, j, i - j)
    while (i <= n && substr(r, i, 1) != "\"" && substr(r, i, 1) != "\047") i++
    if (i > n) { malformed = 1; return }
    q = substr(r, i, 1); i++; j = i
    while (i <= n && substr(r, i, 1) != q) i++
    if (i > n) { malformed = 1; return }
    A[an] = unescape(substr(r, j, i - j))
    i++
  }
  open_el(name)
  if (selfclose) close_el(name)
}
BEGIN { RS = "<" }
NR == 1 { next }
{
  r = $0
  if (mode == "cdata") { if (index(r, "]]>")) mode = ""; next }
  if (mode == "comment") { if (index(r, "-->")) mode = ""; next }
  if (substr(r, 1, 8) == "![CDATA[") { if (!index(substr(r, 9), "]]>")) mode = "cdata"; next }
  if (substr(r, 1, 3) == "!--") { if (!index(substr(r, 4), "-->")) mode = "comment"; next }
  ch = substr(r, 1, 1)
  if (ch == "?" || ch == "!") next
  if (ch == "/") {
    name = substr(r, 2)
    sub(/[ \t\r\n>].*$/, "", name)
    close_el(name)
    next
  }
  parse_tag(r)
}
END {
  if (malformed || !root_seen || sp != 0 || mode != "") exit 4
  print start
  print "All " ncases " test(s) in this result file: " names
  print "(cross-check this list against the tests you just ran — if it names tests you"
  print " didn\047t run, or omits ones you did, this file is from an earlier run, regardless"
  print " of the age above; TestResults.xml is overwritten each run, not appended.)"
  print ""
  if (!nmatch) {
    print "0 tests with [Category(\"" CATEGORY "\")] found in this result file."
    exit 0
  }
  total = 0
  for (m = 1; m <= nmatch; m++) {
    print mfull[m] " [" mres[m] "]"
    print "  Description: " mdesc[m]
    if (mres[m] != "Passed") print "  Note: test did not pass — do not analyze; the screenshot may be stale, partial, or absent."
    if (mshots[m]) {
      for (k = 1; k <= mshots[m]; k++) { print "  Screenshot: " mshot[m, k]; total++ }
    } else {
      print "  Screenshot: (none — not captured)"
    }
    print ""
  }
  print nmatch " visual verification " (nmatch == 1 ? "test" : "tests") ", " total " " (total == 1 ? "screenshot" : "screenshots")
}
' "$results_xml") || status=$?

if [ "$status" -eq "$EXIT_PARSE" ]; then
  echo "Error: failed to parse $results_xml: malformed XML" >&2
  exit "$EXIT_ERROR"
elif [ "$status" -ne 0 ]; then
  echo "Error: awk failed with exit code $status" >&2
  exit "$EXIT_ERROR"
fi

start_time=${out%%$'\n'*}
body=${out#*$'\n'}

age_text=""
start_pattern='^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
if [[ $start_time =~ $start_pattern ]]; then
  # GNU date (Linux, Git Bash) first, then BSD date (macOS).
  if start_epoch=$(date -u -d "${start_time%Z}" +%s 2>/dev/null) \
    || start_epoch=$(date -j -u -f '%Y-%m-%d %H:%M:%SZ' "$start_time" +%s 2>/dev/null); then
    age=$(( $(date -u +%s) - start_epoch ))
    if [ "$age" -lt 0 ]; then
      age_text=" (clock skew — run start-time is in the future)"
    else
      age_text=" — $age seconds ago"
    fi
  fi
fi

echo "Source: $results_xml (run started $start_time$age_text)"
printf '%s\n' "$body"
