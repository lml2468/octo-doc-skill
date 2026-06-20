#!/usr/bin/env sh
# Sync server/overlay.js from the canonical source of truth in the octo-doc
# server repo (assets/overlay.js). The local preview server must render docs with
# the SAME overlay the published server injects, so this file is a mirror — never
# edit server/overlay.js by hand.
#
# Usage: server/sync-overlay.sh   (run from the repo root or anywhere)
set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$DIR/overlay.js"
SRC_URL="${OCTO_OVERLAY_URL:-https://raw.githubusercontent.com/lml2468/octo-doc/main/assets/overlay.js}"

# Prefer a local checkout if present (offline-friendly, avoids drift on a feature
# branch); fall back to fetching the published main.
LOCAL="${OCTO_DOC_DIR:-$DIR/../../octo-doc}/assets/overlay.js"
if [ -f "$LOCAL" ]; then
  cp "$LOCAL" "$DEST"
  echo "synced overlay.js from local checkout: $LOCAL"
else
  curl -fsSL "$SRC_URL" -o "$DEST"
  echo "synced overlay.js from $SRC_URL"
fi
