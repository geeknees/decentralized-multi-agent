#!/usr/bin/env bash
# ABOUTME: Exports SQLite tables to human-readable markdown documents
# ABOUTME: Writes whole_conversation_doc.md and peer_review_doc.md to EXPORT_DIR

set -euo pipefail

DB_PATH="${DB_PATH:-$(dirname "$0")/../db/collective.db}"
EXPORT_DIR="${EXPORT_DIR:-$(dirname "$0")/..}"
COLUMN_SEPARATOR=$'\x1f'
ROW_SEPARATOR=$'\x1e'

mkdir -p "$EXPORT_DIR"

sqlite_stream() {
  sqlite3 -separator "$COLUMN_SEPARATOR" -newline "$ROW_SEPARATOR" "$DB_PATH" "$1"
}

print_blockquote() {
  local content="${1//$'\r'/}"
  local line

  if [ -z "$content" ]; then
    printf '> \n'
    return
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    printf '> %s\n' "$line"
  done <<< "$content"
}

escape_table_cell() {
  local value="${1//$'\r'/}"
  value="${value//|/\\|}"
  value="${value//$'\n'/<br>}"
  printf '%s' "$value"
}

{
  echo "# Whole Conversation Log"
  echo ""
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  while IFS="$COLUMN_SEPARATOR" read -r -d "$ROW_SEPARATOR" ts sender recipient content; do
    if [ "$recipient" = "ALL" ]; then
      echo "## $ts | $sender"
    else
      echo "## $ts | $sender → $recipient"
    fi
    print_blockquote "$content"
    echo ""
  done < <(
    sqlite_stream "SELECT COALESCE(created_at, ''), COALESCE(sender, ''), COALESCE(recipient, ''), COALESCE(content, '') FROM messages ORDER BY id;"
  )
} > "$EXPORT_DIR/whole_conversation_doc.md"

{
  echo "# Peer Review — Decision Log"
  echo ""
  echo "> Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "## Mission Completion"
  echo ""
  while IFS="$COLUMN_SEPARATOR" read -r -d "$ROW_SEPARATOR" mission_status artifact_filename artifact_author completed_at; do
    echo "**Status:** $mission_status  "
    echo "**Artifact:** $artifact_filename  "
    echo "**Artifact author:** $artifact_author  "
    if [ -n "$completed_at" ]; then
      echo "**Completed at:** $completed_at  "
    fi
  done < <(
    sqlite_stream "SELECT COALESCE(status, ''), COALESCE(artifact_filename, 'none'), COALESCE(artifact_author, 'none'), COALESCE(completed_at, '') FROM mission_state WHERE id=1;"
  )
  echo ""
  echo "| Artifact | Reviewer | Vote | Comment |"
  echo "|----------|----------|------|---------|"
  while IFS="$COLUMN_SEPARATOR" read -r -d "$ROW_SEPARATOR" filename reviewer vote comment; do
    printf '| %s | %s | %s | %s |\n' \
      "$(escape_table_cell "$filename")" \
      "$(escape_table_cell "$reviewer")" \
      "$(escape_table_cell "$vote")" \
      "$(escape_table_cell "$comment")"
  done < <(
    sqlite_stream "SELECT COALESCE(filename, ''), COALESCE(reviewer, ''), COALESCE(vote, ''), COALESCE(comment, '') FROM artifact_reviews ORDER BY id;"
  )
  echo ""
  while IFS="$COLUMN_SEPARATOR" read -r -d "$ROW_SEPARATOR" pid proposer title content prop_status created_at; do
    echo "## Proposal #$pid [$prop_status]"
    echo "**タイトル:** $title  "
    echo "**提案者:** $proposer  "
    echo "**日時:** $created_at  "
    echo "**内容:**"
    print_blockquote "$content"
    echo ""
    echo "| Reviewer | Vote | Comment |"
    echo "|----------|------|---------|"
    while IFS="$COLUMN_SEPARATOR" read -r -d "$ROW_SEPARATOR" reviewer vote comment; do
      printf '| %s | %s | %s |\n' \
        "$(escape_table_cell "$reviewer")" \
        "$(escape_table_cell "$vote")" \
        "$(escape_table_cell "$comment")"
    done < <(
      sqlite_stream "SELECT COALESCE(reviewer, ''), COALESCE(vote, ''), COALESCE(comment, '') FROM reviews WHERE proposal_id=$pid ORDER BY id;"
    )
    echo ""
  done < <(
    sqlite_stream "SELECT id, COALESCE(proposer, ''), COALESCE(title, ''), COALESCE(content, ''), COALESCE(status, ''), COALESCE(created_at, '') FROM proposals ORDER BY id;"
  )
} > "$EXPORT_DIR/peer_review_doc.md"

echo "Exported: $EXPORT_DIR/whole_conversation_doc.md"
echo "Exported: $EXPORT_DIR/peer_review_doc.md"
