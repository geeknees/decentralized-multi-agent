#!/usr/bin/env bash
# ABOUTME: Tests that init_db.sh creates the correct SQLite schema
# ABOUTME: Verifies all tables, columns, and the auto_decide trigger exist

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

result=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='trigger' AND name='auto_decide';")
assert_equals "auto_decide" "$result" "auto_decide trigger exists"

result=$(sqlite3 "$DB_PATH" "PRAGMA table_info(agents);" | awk -F'|' '{print $2}' | grep -c "last_read_id" || true)
assert_equals "1" "$result" "agents has last_read_id column"
