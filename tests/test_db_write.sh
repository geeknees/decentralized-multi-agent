#!/usr/bin/env bash
# ABOUTME: Tests for db_write.sh subcommands post_message, create_proposal, vote
# ABOUTME: Verifies each subcommand writes correct data to SQLite

SCRIPTS_DIR="$(dirname "$0")/../scripts"

rm -f "$DB_PATH"
"$SCRIPTS_DIR/init_db.sh" > /dev/null
sqlite3 "$DB_PATH" "INSERT INTO agents (name, role) VALUES ('agent-test', 'Tester');"
sqlite3 "$DB_PATH" "INSERT INTO agents (name, role) VALUES ('agent-reviewer', 'Reviewer');"

# Test: post_message
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" post_message agent-test ALL "Hello everyone"
result=$(sqlite3 "$DB_PATH" "SELECT content FROM messages WHERE sender='agent-test';")
assert_equals "Hello everyone" "$result" "post_message writes content"

recipient=$(sqlite3 "$DB_PATH" "SELECT recipient FROM messages WHERE sender='agent-test';")
assert_equals "ALL" "$recipient" "post_message sets recipient"

# Test: create_proposal
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" create_proposal agent-test "Test Proposal" "This is the body"
result=$(sqlite3 "$DB_PATH" "SELECT title FROM proposals WHERE proposer='agent-test';")
assert_equals "Test Proposal" "$result" "create_proposal writes title"

status=$(sqlite3 "$DB_PATH" "SELECT status FROM proposals WHERE proposer='agent-test';")
assert_equals "OPEN" "$status" "new proposal has OPEN status"

# Test: vote APPROVE
pid=$(sqlite3 "$DB_PATH" "SELECT id FROM proposals WHERE proposer='agent-test';")
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-reviewer "$pid" APPROVE "Looks good"
result=$(sqlite3 "$DB_PATH" "SELECT vote FROM reviews WHERE reviewer='agent-reviewer' AND proposal_id=$pid;")
assert_equals "APPROVE" "$result" "vote writes APPROVE"

# Test: vote REJECT
sqlite3 "$DB_PATH" "INSERT INTO agents (name, role) VALUES ('agent-x', 'Critic');"
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-x "$pid" REJECT "Try alternative Y"
result=$(sqlite3 "$DB_PATH" "SELECT vote FROM reviews WHERE reviewer='agent-x' AND proposal_id=$pid;")
assert_equals "REJECT" "$result" "vote writes REJECT"

# Test: duplicate vote rejected by UNIQUE constraint
set +e
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-reviewer "$pid" APPROVE "Again" 2>/dev/null
exit_code=$?
set -e
assert_equals "1" "$exit_code" "duplicate vote from same agent fails"
