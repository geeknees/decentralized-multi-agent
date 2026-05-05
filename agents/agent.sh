#!/usr/bin/env bash
# ABOUTME: Main agent loop — reads SQLite blackboard, calls an LLM, writes responses
# ABOUTME: Runs indefinitely (or LOOP_MAX iterations in test mode) with LOOP_INTERVAL sleep

set -euo pipefail

AGENT_NAME="${1:-}"
if [ -z "$AGENT_NAME" ]; then
  echo "Usage: $0 <agent-name>" >&2; exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_PATH="${DB_PATH:-$PROJECT_ROOT/db/collective.db}"
LOOP_INTERVAL="${LOOP_INTERVAL:-10}"
LOOP_MAX="${LOOP_MAX:-0}"
SQLITE_BUSY_TIMEOUT_MS="${SQLITE_BUSY_TIMEOUT_MS:-5000}"
ITER=0

export PROJECT_ROOT DB_PATH AGENT_NAME SQLITE_BUSY_TIMEOUT_MS

cd "$PROJECT_ROOT"

ruby_cmd() {
  if command -v mise >/dev/null 2>&1; then
    mise exec -- ruby "$@"
  else
    ruby "$@"
  fi
}

sqlite() { sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT_MS" "$DB_PATH" "$@"; }
sqlite_sep() { sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT_MS" -separator "$1" "$DB_PATH" "$2"; }

sqlite \
  "INSERT INTO agents (name) VALUES ('$AGENT_NAME')
   ON CONFLICT(name) DO UPDATE SET last_seen=CURRENT_TIMESTAMP, status='active';"

echo "[$AGENT_NAME] Started" >&2

while true; do
  MISSION_STATUS=$(sqlite \
    "SELECT COALESCE((SELECT status FROM mission_state WHERE id=1), 'running');" 2>/dev/null || echo "running")
  if [ "$MISSION_STATUS" = "completed" ]; then
    sqlite \
      "UPDATE agents SET last_seen=CURRENT_TIMESTAMP, status='idle' WHERE name='$AGENT_NAME';" 2>/dev/null || true
    echo "[$AGENT_NAME] Mission completed; exiting" >&2
    break
  fi

  LAST_READ=$(sqlite "SELECT last_read_id FROM agents WHERE name='$AGENT_NAME';")

  NEW_MSGS=$(sqlite_sep $'\x01' \
    "SELECT id, sender, recipient, content, created_at FROM messages
     WHERE id > $LAST_READ AND (recipient='ALL' OR recipient='$AGENT_NAME') ORDER BY id;")

  OPEN_PROPS=$(sqlite_sep $'\x01' \
    "SELECT p.id, p.proposer, p.title, p.content,
            COALESCE(GROUP_CONCAT(r.reviewer||':'||r.vote, ', '),'none')
     FROM proposals p LEFT JOIN reviews r ON r.proposal_id=p.id
     WHERE p.status='OPEN' GROUP BY p.id;")

  MISSION_SUMMARY=$(sqlite \
    "SELECT 'status=' || status ||
            ', artifact=' || COALESCE(artifact_filename, 'none') ||
            ', artifact_author=' || COALESCE(artifact_author, 'none')
     FROM mission_state WHERE id=1;" 2>/dev/null || echo "status=running, artifact=none")

  ARTIFACT_REVIEWS=$(sqlite_sep $'\x01' \
    "SELECT filename, reviewer, vote, COALESCE(comment, ''), created_at
     FROM artifact_reviews ORDER BY id;" 2>/dev/null || true)

  MY_ROLE=$(sqlite "SELECT COALESCE(role,'unassigned') FROM agents WHERE name='$AGENT_NAME';")
  PURPOSE=$(cat "$PROJECT_ROOT/purpose_doc.md")
  MSG_COUNT=$(sqlite "SELECT COUNT(*) FROM messages;")

  MSGS_TEXT=""
  while IFS=$'\x01' read -r mid sender recipient content ts; do
    [ -z "$mid" ] && continue
    MSGS_TEXT+="[$ts] $sender → $recipient: $content"$'\n'
  done <<< "$NEW_MSGS"

  PROPS_TEXT=""
  while IFS=$'\x01' read -r pid proposer title content votes; do
    [ -z "$pid" ] && continue
    PROPS_TEXT+="Proposal #$pid ($proposer): $title | $content | votes: $votes"$'\n'
  done <<< "$OPEN_PROPS"

  ARTIFACT_REVIEWS_TEXT=""
  while IFS=$'\x01' read -r filename reviewer vote comment ts; do
    [ -z "$filename" ] && continue
    ARTIFACT_REVIEWS_TEXT+="[$ts] $filename | $reviewer: $vote | $comment"$'\n'
  done <<< "$ARTIFACT_REVIEWS"

  PROMPT="Agent: $AGENT_NAME | Role: $MY_ROLE | Total messages: $MSG_COUNT
Mission completion: $MISSION_SUMMARY

Purpose:
$PURPOSE

New messages:
${MSGS_TEXT:-（なし）}

Open proposals:
${PROPS_TEXT:-（なし）}

Artifact reviews:
${ARTIFACT_REVIEWS_TEXT:-（なし）}

agents/CLAUDE.md の指示に従い、JSONでアクションを返してください。"

  RESPONSE=$(printf '%s' "$PROMPT" | "$PROJECT_ROOT/scripts/llm_call.sh" 2>/dev/null || echo '{"actions":[]}')

  JSON=$(echo "$RESPONSE" | ruby_cmd "$PROJECT_ROOT/scripts/extract_json.rb" 2>/dev/null \
        || echo '{"actions":[]}')

  echo "$JSON" | ruby_cmd "$PROJECT_ROOT/scripts/run_actions.rb" 2>/dev/null || true

  MAX_ID=$(sqlite "SELECT COALESCE(MAX(id),0) FROM messages;")
  sqlite \
    "UPDATE agents SET last_read_id=$MAX_ID, last_seen=CURRENT_TIMESTAMP WHERE name='$AGENT_NAME';"

  DB_PATH="$DB_PATH" EXPORT_DIR="$PROJECT_ROOT" \
    "$PROJECT_ROOT/scripts/export_docs.sh" > /dev/null 2>&1 || true

  ITER=$((ITER + 1))
  [ "$LOOP_MAX" -gt 0 ] && [ "$ITER" -ge "$LOOP_MAX" ] && break

  sleep "$LOOP_INTERVAL"
done
