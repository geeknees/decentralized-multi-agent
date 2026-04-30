#!/usr/bin/env bash
# ABOUTME: Launches all agents in a tmux session named 'autonomous'
# ABOUTME: One tmux window per agent; initializes DB if not present

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <agent-name-1> [agent-name-2] ..." >&2
  exit 1
fi

SESSION="autonomous"

if [ ! -f "$PROJECT_ROOT/db/collective.db" ]; then
  echo "Initializing database..."
  "$PROJECT_ROOT/scripts/init_db.sh"
fi

tmux kill-session -t "$SESSION" 2>/dev/null || true

FIRST="$1"; shift

tmux new-session -d -s "$SESSION" -n "$FIRST" \
  "bash '$PROJECT_ROOT/agents/agent.sh' '$FIRST'; echo 'Agent exited. Press enter.'; read"

for name in "$@"; do
  tmux new-window -t "$SESSION" -n "$name" \
    "bash '$PROJECT_ROOT/agents/agent.sh' '$name'; echo 'Agent exited. Press enter.'; read"
done

echo "Session '$SESSION' started with agents: $FIRST $*"
echo "Attach: tmux attach -t $SESSION"
echo "Stop:   tmux kill-session -t $SESSION"
