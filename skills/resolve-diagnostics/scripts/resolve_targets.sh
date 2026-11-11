#!/usr/bin/env bash
# Prints the solution-root-relative path of every .cs file among the given paths
# (directories are expanded recursively), one per line. Everything else is dropped
# with a note on stderr. Exit code 3 when nothing remains.
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $(basename "$0") <unity-project-root> <path>..." >&2
  exit 2
fi

root="$(cd "$1" && pwd)"
shift

# ponytail: "belongs to the solution" is approximated as "under the project root, outside
# Library/ and Temp/"; parse the .sln/.csproj instead if generated projects ever diverge.
emit() {
  local abs="$1"
  case "$abs" in
    "$root"/Library/*|"$root"/Temp/*) echo "skip (not in solution): $abs" >&2 ;;
    "$root"/*) printf '%s\n' "${abs#"$root"/}" ;;
    *) echo "skip (outside project root): $abs" >&2 ;;
  esac
}

resolve() {
  for p in "$@"; do
    if [ -d "$p" ]; then
      abs="$(cd "$p" && pwd)"
      while IFS= read -r f; do emit "$f"; done < <(find "$abs" -type f -name '*.cs' | sort)
    elif [ -f "$p" ]; then
      case "$p" in
        *.cs) emit "$(cd "$(dirname "$p")" && pwd)/$(basename "$p")" ;;
        *) echo "skip (not a .cs file): $p" >&2 ;;
      esac
    else
      echo "skip (not found): $p" >&2
    fi
  done
}

result="$(resolve "$@")"
[ -n "$result" ] || exit 3
printf '%s\n' "$result"
