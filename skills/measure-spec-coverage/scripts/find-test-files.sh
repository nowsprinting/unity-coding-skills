#!/usr/bin/env bash
# Prints the absolute path of every .cs file with a `// Test-basis:` line naming the given
# specification document, one per line. Exit code 3 when no file names it.
#
# A test written in the repository that holds the document names it by the path from that
# repository's root; a test written in a superproject names it by the path from the
# superproject's root. Each repository level is searched with the path from its own root.
set -euo pipefail

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $(basename "$0") <specification document path>" >&2
  exit 2
fi

spec="$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")"
repo="$(git -C "$(dirname "$spec")" rev-parse --show-toplevel)"

# git grep cannot combine --recurse-submodules with --untracked, and a run's test files may
# still be uncommitted, so grep walks the working tree instead.
result="$(
  while [ -n "$repo" ]; do
    rel="${spec#"$repo"/}"
    pattern="^// Test-basis: $(printf '%s' "$rel" | sed 's/[][\.*^$+?(){}|]/\\&/g')[[:space:]]*\$"
    grep -rlE --include='*.cs' --exclude-dir=.git --exclude-dir=Library --exclude-dir=Temp \
      --exclude-dir=Logs --exclude-dir=obj -e "$pattern" "$repo" || true
    repo="$(git -C "$repo" rev-parse --show-superproject-working-tree)"
  done | sort -u
)"
[ -n "$result" ] || exit 3
printf '%s\n' "$result"
