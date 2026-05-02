#!/usr/bin/env bash
# ABOUTME: Resets agent state and conversation history for a new purpose
# ABOUTME: Archives current DB and artifacts, then reinitializes for a fresh run

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_PATH="${DB_PATH:-$PROJECT_ROOT/db/collective.db}"
NEW_PURPOSE="${1:-}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_DIR="$PROJECT_ROOT/archive/$TIMESTAMP"
mkdir -p "$ARCHIVE_DIR"

# Archive current DB
if [ -f "$DB_PATH" ]; then
  cp "$DB_PATH" "$ARCHIVE_DIR/collective.db"
  echo "Archived DB → archive/$TIMESTAMP/collective.db"
fi

# Archive current purpose_doc and any artifact files
cp "$PROJECT_ROOT/purpose_doc.md" "$ARCHIVE_DIR/purpose_doc.md" 2>/dev/null || true

ARTIFACT_FILES=$(sqlite3 "$DB_PATH" \
  "SELECT DISTINCT filename FROM artifacts;" 2>/dev/null || true)

# Archive markdown artifacts listed in purpose_doc (best-effort)
for f in "$PROJECT_ROOT"/*.md; do
  base=$(basename "$f")
  [ "$base" = "purpose_doc.md" ] && continue
  [ "$base" = "peer_review_doc.md" ] && continue
  [ "$base" = "whole_conversation_doc.md" ] && continue
  [ "$base" = "README.md" ] && continue
  cp "$f" "$ARCHIVE_DIR/$base" 2>/dev/null || true
  echo "Archived artifact → archive/$TIMESTAMP/$base"
done

# Soft reset: clear conversation state, preserve agent list structure
sqlite3 "$DB_PATH" << 'SQL'
DELETE FROM reviews;
DELETE FROM proposals;
DELETE FROM messages;
UPDATE agents SET role = NULL, last_read_id = 0, status = 'active';
SQL

echo "Reset: messages, proposals, reviews cleared; agent roles reset"

# Replace purpose_doc if a new one was provided
if [ -n "$NEW_PURPOSE" ]; then
  if [ ! -f "$NEW_PURPOSE" ]; then
    echo "Error: '$NEW_PURPOSE' not found" >&2
    exit 1
  fi
  cp "$NEW_PURPOSE" "$PROJECT_ROOT/purpose_doc.md"
  echo "purpose_doc.md replaced with $NEW_PURPOSE"
else
  echo ""
  echo "Next: edit purpose_doc.md, then run:"
  echo "  scripts/launch.sh agent-alpha agent-beta agent-gamma"
fi
