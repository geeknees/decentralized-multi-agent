#!/usr/bin/env bash
# ABOUTME: Tests that init_db.sh creates the correct SQLite schema
# ABOUTME: Verifies tables, columns, mission state, and decision triggers exist

SCRIPTS_DIR="$(dirname "$0")/../scripts"

rm -f "$DB_PATH"
"$SCRIPTS_DIR/init_db.sh" > /dev/null

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='agents';")
assert_equals "agents" "$result" "agents table exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='messages';")
assert_equals "messages" "$result" "messages table exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='proposals';")
assert_equals "proposals" "$result" "proposals table exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='reviews';")
assert_equals "reviews" "$result" "reviews table exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='mission_state';")
assert_equals "mission_state" "$result" "mission_state table exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='artifact_reviews';")
assert_equals "artifact_reviews" "$result" "artifact_reviews table exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='trigger' AND name='auto_decide';")
assert_equals "auto_decide" "$result" "auto_decide trigger exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='trigger' AND name='auto_complete_mission';")
assert_equals "auto_complete_mission" "$result" "auto_complete_mission trigger exists"

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='trigger' AND name='auto_reopen_mission';")
assert_equals "auto_reopen_mission" "$result" "auto_reopen_mission trigger exists"

result=$(sqlite3 "$DB_PATH" "PRAGMA table_info(agents);" | awk -F'|' '{print $2}' | grep -c "last_read_id" || true)
assert_equals "1" "$result" "agents has last_read_id column"

result=$(sqlite3 "$DB_PATH" "SELECT status FROM mission_state WHERE id=1;")
assert_equals "running" "$result" "mission_state starts in running status"
