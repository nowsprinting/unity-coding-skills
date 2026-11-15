#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $(basename "$0") <unity-project-root>" >&2
  echo "Exits 0 as soon as Editor.log shows a test run started, 1 when none started within UNITY_RUN_TESTS_DISCARD_SCENE_CHANGES_DELAY_SECONDS (default 20) seconds. macOS only." >&2
  exit 2
fi

# Which file the Editor writes to depends on its version and settings
# (see resources/troubleshooting-run-unity-tests.md), so both are watched
# instead of resolving the one in use.
logs=(
  "$1/Logs/Editor.log"
  "$HOME/Library/Logs/Unity/Editor.log"
)

offsets=()
for log in "${logs[@]}"; do
  offsets+=("$({ wc -c <"$log"; } 2>/dev/null || echo 0)")
done

# ponytail: Unity Test Framework itself logs nothing when a run starts, so
# these are side effects: the first needs an IPrebuildSetup class in the
# project (e.g., com.unity.test-framework.performance), the second a Play Mode
# run with domain reload. An Edit Mode run with neither always exits 1.
# Growth of the log is not used instead: unrelated lines (licensing, asset
# refresh) are written while the dialog blocks the run, and taking them for a
# start would leave the dialog open.
markers='Executing IPrebuildSetup for: |Reloading assemblies for play mode'

deadline=$((SECONDS + ${UNITY_RUN_TESTS_DISCARD_SCENE_CHANGES_DELAY_SECONDS:-20}))
while :; do
  for i in "${!logs[@]}"; do
    # Not `grep -q`: it exits at the first match, and under pipefail the SIGPIPE
    # it sends to `tail` fails the pipeline.
    if tail -c "+$((offsets[i] + 1))" "${logs[i]}" 2>/dev/null |
      grep -E "$markers" >/dev/null; then
      exit 0
    fi
  done
  if [ "$SECONDS" -ge "$deadline" ]; then
    exit 1
  fi
  sleep 1
done
