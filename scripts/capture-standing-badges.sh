#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/standing-badge-screenshots"
PROJECT="$ROOT/Farkle Score..xcodeproj"
SCHEME="Farkle Score."
DESTINATION="${STANDING_BADGE_DESTINATION:-platform=macOS}"

rm -rf "$OUT"
mkdir -p "$OUT"
touch "$OUT/.capture"

cd "$ROOT"

xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -skip-testing:"Farkle Score.UITests" \
  -only-testing:"Farkle Score.Tests/StandingBadgeScreenshotExporterTests/testExportStandingBadgeScreenshots"

# XCTest runs inside the app sandbox; copy PNGs from the container temp export folder.
SANDBOX_TMP="$HOME/Library/Containers/com.nathanfennel.Farkle-Score-/Data/tmp/standing-badge-screenshots"
if [[ -d "$SANDBOX_TMP" ]]; then
  cp "$SANDBOX_TMP"/*.png "$OUT/" 2>/dev/null || true
fi

# Also pick up Xcode test output attachments when present.
RESULT=$(ls -t "$HOME/Library/Developer/Xcode/DerivedData/Farkle_Score."*/Logs/Test/Test-Farkle*.xcresult 2>/dev/null | head -1 || true)
if [[ -n "$RESULT" ]]; then
  ATTACH_DIR=$(find "$RESULT" -type d -name "standing-badge-screenshots" 2>/dev/null | head -1 || true)
  if [[ -n "$ATTACH_DIR" ]]; then
    cp "$ATTACH_DIR"/*.png "$OUT/" 2>/dev/null || true
  fi
fi

echo "Screenshots written to: $OUT"
ls "$OUT"/*.png 2>/dev/null | wc -l | xargs echo "PNG count:"

if [[ "$(uname)" == "Darwin" ]]; then
  open "$OUT"
fi
