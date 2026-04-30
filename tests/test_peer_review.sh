#!/usr/bin/env bash
# ABOUTME: Tests for the auto_decide trigger and peer review decision semantics
# ABOUTME: Verifies 2-approval rule, REJECT behavior, and UNIQUE constraint

SCRIPTS_DIR="$(dirname "$0")/../scripts"

_setup() {
  rm -f "$DB_PATH"
  "$SCRIPTS_DIR/init_db.sh" > /dev/null
  sqlite3 "$DB_PATH" << 'SQL'
INSERT INTO agents (name, role) VALUES ('agent-a', 'Proposer');
INSERT INTO agents (name, role) VALUES ('agent-b', 'Researcher');
INSERT INTO agents (name, role) VALUES ('agent-c', 'Critic');
INSERT INTO proposals (proposer, title, content) VALUES ('agent-a', 'Alpha Proposal', 'Do something');
SQL
}

_setup
PID=$(sqlite3 "$DB_PATH" "SELECT id FROM proposals WHERE title='Alpha Proposal';")

# Test 1: 1 APPROVE → proposal stays OPEN
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-a "$PID" APPROVE "I like it"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM proposals WHERE id=$PID;")
assert_equals "OPEN" "$result" "1 APPROVE: status stays OPEN"

# Test 2: 2nd APPROVE → auto DECIDED
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-b "$PID" APPROVE "Agree"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM proposals WHERE id=$PID;")
assert_equals "DECIDED" "$result" "2 APPROVEs: status becomes DECIDED"

# Test 3: REJECT keeps proposal OPEN
_setup
PID=$(sqlite3 "$DB_PATH" "SELECT id FROM proposals WHERE title='Alpha Proposal';")
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-c "$PID" REJECT "Bad idea, try X instead"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM proposals WHERE id=$PID;")
assert_equals "OPEN" "$result" "REJECT keeps status OPEN"

# Test 4: APPROVE after REJECT still works (2 APPROVEs decide even with a REJECT)
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-a "$PID" APPROVE "Still yes"
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-b "$PID" APPROVE "Me too"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM proposals WHERE id=$PID;")
assert_equals "DECIDED" "$result" "2 APPROVEs decide even alongside a REJECT"

# Test 5: Same agent cannot vote twice
_setup
PID=$(sqlite3 "$DB_PATH" "SELECT id FROM proposals WHERE title='Alpha Proposal';")
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-a "$PID" APPROVE "First" > /dev/null
set +e
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" vote agent-a "$PID" APPROVE "Second" 2>/dev/null
dup_exit=$?
set -e
assert_equals "1" "$dup_exit" "duplicate vote from same agent rejected"
