#!/usr/bin/env bash
# ABOUTME: Tests for agent.sh startup registration and first-loop message writing
# ABOUTME: Uses a mock claude binary to avoid real API calls

SCRIPTS_DIR="$(dirname "$0")/../scripts"
AGENTS_DIR="$(dirname "$0")/../agents"
PROJECT_ROOT="$(dirname "$0")/.."

MOCK_DIR=$(mktemp -d)
cleanup() { rm -rf "$MOCK_DIR"; }
trap cleanup EXIT

cat > "$MOCK_DIR/claude" << 'MOCK'
#!/usr/bin/env bash
# Reads stdin, always returns a fixed role-declaration + hello message
cat << 'RESP'
{"actions": [{"type": "set_role", "role": "Tester"}, {"type": "post_message", "recipient": "ALL", "content": "Hello from mock-agent"}]}
RESP
MOCK
chmod +x "$MOCK_DIR/claude"

export PATH="$MOCK_DIR:$PATH"

rm -f "$DB_PATH"
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/init_db.sh" > /dev/null

# Run agent for exactly 1 iteration then stop
LOOP_MAX=1 DB_PATH="$DB_PATH" \
  bash "$AGENTS_DIR/agent.sh" mock-agent > /dev/null 2>&1

# Test 1: agent registered in DB
result=$(sqlite3 "$DB_PATH" "SELECT name FROM agents WHERE name='mock-agent';")
assert_equals "mock-agent" "$result" "agent registers in agents table"

# Test 2: agent set its role
result=$(sqlite3 "$DB_PATH" "SELECT role FROM agents WHERE name='mock-agent';")
assert_equals "Tester" "$result" "agent self-assigns role"

# Test 3: agent posted a message
result=$(sqlite3 "$DB_PATH" "SELECT content FROM messages WHERE sender='mock-agent';")
assert_contains "Hello from mock-agent" "$result" "agent posted intro message"

# Test 4: last_read_id advances after loop
result=$(sqlite3 "$DB_PATH" "SELECT last_read_id FROM agents WHERE name='mock-agent';")
[ "$result" -ge 1 ] && \
  { echo "  PASS: last_read_id advanced"; PASS=$((PASS+1)); } || \
  { echo "  FAIL: last_read_id did not advance (got: $result)"; FAIL=$((FAIL+1)); }
