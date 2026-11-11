#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $(basename "$0") <unity-project-root>" >&2
  exit 2
fi

settings="$1/ProjectSettings/ProjectSettings.asset"
if [ ! -f "$settings" ]; then
  echo "Error: file not found: $settings" >&2
  exit 1
fi

# Prints nothing when ProjectSettings.asset is serialized as binary.

# Screen settings (flat keys)
grep -E '^  (fullscreenMode|defaultScreenWidth|defaultScreenHeight): ' "$settings" | sed -E 's/^ +//' || true

# Build settings (per-build-target maps): print the Standalone entry; a missing
# line means the project uses Unity's default for that setting
awk '
  /^  (scriptingBackend|il2cppCodeGeneration|managedStrippingLevel):/ {
    key = $1; sub(/:$/, "", key); in_block = 1; next
  }
  in_block && $1 == "Standalone:" { print key ": " $2; in_block = 0; next }
  in_block && !/^    / { in_block = 0 }
' "$settings"
