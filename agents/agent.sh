#!/usr/bin/env bash
# ABOUTME: Main agent loop — reads SQLite blackboard, calls Claude, writes responses
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
ITER=0

export PROJECT_ROOT DB_PATH AGENT_NAME

cd "$PROJECT_ROOT"

sqlite3 "$DB_PATH" \
  "INSERT INTO agents (name) VALUES ('$AGENT_NAME')
   ON CONFLICT(name) DO UPDATE SET last_seen=CURRENT_TIMESTAMP, status='active';"

echo "[$AGENT_NAME] Started" >&2

while true; do
  LAST_READ=$(sqlite3 "$DB_PATH" "SELECT last_read_id FROM agents WHERE name='$AGENT_NAME';")

  NEW_MSGS=$(sqlite3 -separator $'\x01' "$DB_PATH" \
    "SELECT id, sender, recipient, content, created_at FROM messages
     WHERE id > $LAST_READ AND (recipient='ALL' OR recipient='$AGENT_NAME') ORDER BY id;")

  OPEN_PROPS=$(sqlite3 -separator $'\x01' "$DB_PATH" \
    "SELECT p.id, p.proposer, p.title, p.content,
            COALESCE(GROUP_CONCAT(r.reviewer||':'||r.vote, ', '),'none')
     FROM proposals p LEFT JOIN reviews r ON r.proposal_id=p.id
     WHERE p.status='OPEN' GROUP BY p.id;")

  MY_ROLE=$(sqlite3 "$DB_PATH" "SELECT COALESCE(role,'unassigned') FROM agents WHERE name='$AGENT_NAME';")
  PURPOSE=$(cat "$PROJECT_ROOT/purpose_doc.md")

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

  PROMPT="Agent: $AGENT_NAME | Role: $MY_ROLE

Purpose:
$PURPOSE

New messages:
${MSGS_TEXT:-（なし）}

Open proposals:
${PROPS_TEXT:-（なし）}

agents/CLAUDE.md の指示に従い、JSONでアクションを返してください。"

  RESPONSE=$(echo "$PROMPT" | claude --print 2>/dev/null || echo '{"actions":[]}')

  JSON=$(echo "$RESPONSE" | ruby "$PROJECT_ROOT/scripts/extract_json.rb" 2>/dev/null \
        || echo '{"actions":[]}')

  echo "$JSON" | ruby "$PROJECT_ROOT/scripts/run_actions.rb" 2>/dev/null || true

  MAX_ID=$(sqlite3 "$DB_PATH" "SELECT COALESCE(MAX(id),0) FROM messages;")
  sqlite3 "$DB_PATH" \
    "UPDATE agents SET last_read_id=$MAX_ID, last_seen=CURRENT_TIMESTAMP WHERE name='$AGENT_NAME';"

  DB_PATH="$DB_PATH" EXPORT_DIR="$PROJECT_ROOT" \
    "$PROJECT_ROOT/scripts/export_docs.sh" > /dev/null 2>&1 || true

  ITER=$((ITER + 1))
  [ "$LOOP_MAX" -gt 0 ] && [ "$ITER" -ge "$LOOP_MAX" ] && break

  sleep "$LOOP_INTERVAL"
done
