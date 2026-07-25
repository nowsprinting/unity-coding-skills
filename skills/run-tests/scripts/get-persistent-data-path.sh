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

company=$(grep -m 1 '^  companyName: ' "$settings" | sed -E 's/^  companyName: //' | tr -d '"')
product=$(grep -m 1 '^  productName: ' "$settings" | sed -E 's/^  productName: //' | tr -d '"')

if [ -z "$company" ] || [ -z "$product" ]; then
  echo "Error: missing companyName or productName in $settings" >&2
  exit 1
fi

# Per Unity's Application.persistentDataPath docs
# (https://docs.unity3d.com/ScriptReference/Application-persistentDataPath.html).
# This resolves the Editor path only: on macOS the Player uses a different,
# lowercased "unity.<company>.<product>" path unless that Editor directory
# already exists, so this script is not valid for standalone-player runs.
case "$(uname -s)" in
  Darwin)
    echo "$HOME/Library/Application Support/$company/$product"
    ;;
  Linux)
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/unity3d/$company/$product"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "$USERPROFILE/AppData/LocalLow/$company/$product"
    ;;
  *)
    echo "Error: unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac
