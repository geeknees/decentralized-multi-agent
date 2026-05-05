#!/usr/bin/env bash
# ABOUTME: Tests mission completion flow from artifact write through peer review
# ABOUTME: Verifies artifact review votes complete the mission and stop agents

SCRIPTS_DIR="$(dirname "$0")/../scripts"
AGENTS_DIR="$(dirname "$0")/../agents"
PROJECT_ROOT="$(dirname "$0")/.."

ruby_cmd() {
  if command -v mise >/dev/null 2>&1; then
    mise exec -- ruby "$@"
  else
    ruby "$@"
  fi
}

rm -f "$DB_PATH" "$PROJECT_ROOT/test_output.md"
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/init_db.sh" > /dev/null
sqlite3 "$DB_PATH" "INSERT INTO agents (name, role) VALUES ('agent-a', 'Implementer'), ('agent-b', 'Critic'), ('agent-c', 'Researcher');"

AGENT_NAME=agent-a DB_PATH="$DB_PATH" PROJECT_ROOT="$PROJECT_ROOT" \
  ruby_cmd "$SCRIPTS_DIR/run_actions.rb" << 'JSON'
{"actions":[{"type":"write_artifact","filename":"test_output.md","content":"# Test Output\n"}]}
JSON

result=$(sqlite3 "$DB_PATH" "SELECT status FROM mission_state WHERE id=1;")
assert_equals "review" "$result" "write_artifact moves mission to review"

result=$(sqlite3 "$DB_PATH" "SELECT artifact_filename FROM mission_state WHERE id=1;")
assert_equals "test_output.md" "$result" "write_artifact records artifact filename"

result=$(sqlite3 "$DB_PATH" "SELECT artifact_author FROM mission_state WHERE id=1;")
assert_equals "agent-a" "$result" "write_artifact records artifact author"

set +e
DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" review_artifact agent-a test_output.md APPROVE "Self review" 2>/dev/null
self_review_exit=$?
set -e
assert_equals "1" "$self_review_exit" "artifact author cannot review own artifact"

DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" review_artifact agent-b test_output.md REJECT "Missing required detail"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM mission_state WHERE id=1;")
assert_equals "running" "$result" "artifact REJECT returns mission to running"

AGENT_NAME=agent-a DB_PATH="$DB_PATH" PROJECT_ROOT="$PROJECT_ROOT" \
  ruby_cmd "$SCRIPTS_DIR/run_actions.rb" << 'JSON'
{"actions":[{"type":"write_artifact","filename":"test_output.md","content":"# Revised Test Output\n"}]}
JSON

result=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM artifact_reviews WHERE filename='test_output.md';")
assert_equals "0" "$result" "rewriting artifact clears stale artifact reviews"

DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" review_artifact agent-b test_output.md APPROVE "Looks complete"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM mission_state WHERE id=1;")
assert_equals "review" "$result" "1 artifact APPROVE keeps mission in review"

DB_PATH="$DB_PATH" "$SCRIPTS_DIR/db_write.sh" review_artifact agent-c test_output.md APPROVE "Meets criteria"
result=$(sqlite3 "$DB_PATH" "SELECT status FROM mission_state WHERE id=1;")
assert_equals "completed" "$result" "2 artifact APPROVEs complete mission"

MOCK_DIR=$(mktemp -d)
cleanup_mission_completion() {
  rm -rf "$MOCK_DIR"
  rm -f "$PROJECT_ROOT/test_output.md"
}
trap cleanup_mission_completion EXIT

cat > "$MOCK_DIR/claude" << 'MOCK'
#!/usr/bin/env bash
echo "claude should not be called" >&2
exit 42
MOCK
chmod +x "$MOCK_DIR/claude"

export PATH="$MOCK_DIR:$PATH"

set +e
LOOP_MAX=1 DB_PATH="$DB_PATH" \
  bash "$AGENTS_DIR/agent.sh" completed-agent > /dev/null 2>&1
agent_exit=$?
set -e
assert_equals "0" "$agent_exit" "completed mission makes agent exit without claude"
