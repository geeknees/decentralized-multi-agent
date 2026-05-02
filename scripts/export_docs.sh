#!/usr/bin/env bash
# ABOUTME: Exports SQLite tables to human-readable markdown documents
# ABOUTME: Writes whole_conversation_doc.md and peer_review_doc.md to EXPORT_DIR

DB_PATH="${DB_PATH:-$(dirname "$0")/../db/collective.db}"
EXPORT_DIR="${EXPORT_DIR:-$(dirname "$0")/..}"

tmpmsgs=$(mktemp)
tmpprop=$(mktemp)
trap "rm -f $tmpmsgs $tmpprop" EXIT

sqlite3 "$DB_PATH" "SELECT created_at, sender, recipient, content FROM messages ORDER BY id;" > "$tmpmsgs"

{
  echo "# Whole Conversation Log"
  echo ""
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  while IFS='|' read -r ts sender recipient content; do
    if [ "$recipient" = "ALL" ]; then
      echo "## $ts | $sender"
    else
      echo "## $ts | $sender → $recipient"
    fi
    echo "> $content"
    echo ""
  done < "$tmpmsgs"
} > "$EXPORT_DIR/whole_conversation_doc.md"

sqlite3 "$DB_PATH" "SELECT id, proposer, title, content, status, created_at FROM proposals ORDER BY id;" > "$tmpprop"

{
  echo "# Peer Review — Decision Log"
  echo ""
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "## Mission Completion"
  echo ""
  sqlite3 "$DB_PATH" \
    "SELECT status, COALESCE(artifact_filename, 'none'), COALESCE(completed_at, '')
     FROM mission_state WHERE id=1;" | \
  while IFS='|' read -r mission_status artifact_filename completed_at; do
    echo "**Status:** $mission_status  "
    echo "**Artifact:** $artifact_filename  "
    if [ -n "$completed_at" ]; then
      echo "**Completed at:** $completed_at  "
    fi
  done
  echo ""
  echo "| Artifact | Reviewer | Vote | Comment |"
  echo "|----------|----------|------|---------|"
  sqlite3 "$DB_PATH" \
    "SELECT filename, reviewer, vote, COALESCE(comment, '') FROM artifact_reviews ORDER BY id;" | \
  while IFS='|' read -r filename reviewer vote comment; do
    echo "| $filename | $reviewer | $vote | $comment |"
  done
  echo ""
  while IFS='|' read -r pid proposer title content prop_status created_at; do
    echo "## Proposal #$pid [$prop_status]"
    echo "**タイトル:** $title  "
    echo "**提案者:** $proposer  "
    echo "**日時:** $created_at  "
    echo "**内容:** $content"
    echo ""
    echo "| Reviewer | Vote | Comment |"
    echo "|----------|------|---------|"
    sqlite3 "$DB_PATH" \
      "SELECT reviewer, vote, COALESCE(comment,'') FROM reviews WHERE proposal_id=$pid ORDER BY id;" | \
    while IFS='|' read -r reviewer vote comment; do
      echo "| $reviewer | $vote | $comment |"
    done
    echo ""
  done < "$tmpprop"
} > "$EXPORT_DIR/peer_review_doc.md"

echo "Exported: $EXPORT_DIR/whole_conversation_doc.md"
echo "Exported: $EXPORT_DIR/peer_review_doc.md"
