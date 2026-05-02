#!/usr/bin/env bash
# ABOUTME: Tests that export_docs.sh generates correctly formatted markdown files
# ABOUTME: Verifies whole_conversation_doc.md and peer_review_doc.md content

SCRIPTS_DIR="$(dirname "$0")/../scripts"
EXPORT_DIR=$(mktemp -d)

rm -f "$DB_PATH"
"$SCRIPTS_DIR/init_db.sh" > /dev/null
sqlite3 "$DB_PATH" << 'SQL'
INSERT INTO agents (name, role) VALUES ('agent-a', 'Researcher');
INSERT INTO agents (name, role) VALUES ('agent-b', 'Critic');
INSERT INTO messages (sender, recipient, content) VALUES ('agent-a', 'ALL', 'Hello from agent-a');
INSERT INTO messages (sender, recipient, content) VALUES ('agent-b', 'agent-a', 'Reply from agent-b');
INSERT INTO proposals (proposer, title, content) VALUES ('agent-a', 'Test Proposal', 'Proposal body here');
INSERT INTO reviews (proposal_id, reviewer, vote, comment) VALUES (1, 'agent-a', 'APPROVE', 'Good');
INSERT INTO reviews (proposal_id, reviewer, vote, comment) VALUES (1, 'agent-b', 'APPROVE', 'Agree');
UPDATE mission_state SET status='review', artifact_filename='output.md', artifact_written_at=CURRENT_TIMESTAMP;
INSERT INTO artifact_reviews (filename, reviewer, vote, comment) VALUES ('output.md', 'agent-a', 'APPROVE', 'Complete');
SQL

DB_PATH="$DB_PATH" EXPORT_DIR="$EXPORT_DIR" "$SCRIPTS_DIR/export_docs.sh" > /dev/null

# Test 1: whole_conversation_doc.md exists
[ -f "$EXPORT_DIR/whole_conversation_doc.md" ] && \
  { echo "  PASS: whole_conversation_doc.md created"; PASS=$((PASS+1)); } || \
  { echo "  FAIL: whole_conversation_doc.md missing"; FAIL=$((FAIL+1)); }

conv=$(cat "$EXPORT_DIR/whole_conversation_doc.md")
assert_contains "Hello from agent-a" "$conv" "conversation has message content"
assert_contains "agent-a" "$conv" "conversation has sender name"
assert_contains "Reply from agent-b" "$conv" "conversation has reply content"

# Test 2: peer_review_doc.md exists
[ -f "$EXPORT_DIR/peer_review_doc.md" ] && \
  { echo "  PASS: peer_review_doc.md created"; PASS=$((PASS+1)); } || \
  { echo "  FAIL: peer_review_doc.md missing"; FAIL=$((FAIL+1)); }

pr=$(cat "$EXPORT_DIR/peer_review_doc.md")
assert_contains "DECIDED" "$pr" "peer_review shows DECIDED status"
assert_contains "Test Proposal" "$pr" "peer_review shows proposal title"
assert_contains "APPROVE" "$pr" "peer_review shows votes"
assert_contains "Mission Completion" "$pr" "peer_review shows mission section"
assert_contains "output.md" "$pr" "peer_review shows artifact review"

rm -rf "$EXPORT_DIR"
