#!/usr/bin/env bash
# ABOUTME: CLI helper for agents to write to the SQLite shared blackboard
# ABOUTME: Subcommands: post_message, create_proposal, vote, review_artifact

set -euo pipefail

DB_PATH="${DB_PATH:-$(dirname "$0")/../db/collective.db}"

sq() { printf '%s' "$1" | sed "s/'/''/g"; }

usage() {
  echo "Usage:"
  echo "  db_write.sh post_message <sender> <recipient> <content>"
  echo "  db_write.sh create_proposal <proposer> <title> <content>"
  echo "  db_write.sh vote <reviewer> <proposal_id> <APPROVE|REJECT> <comment>"
  echo "  db_write.sh review_artifact <reviewer> <filename> <APPROVE|REJECT> <comment>"
  exit 1
}

cmd="${1:-}"
case "$cmd" in
  post_message)
    sender="$(sq "${2:?sender required}")"
    recipient="$(sq "${3:?recipient required}")"
    content="$(sq "${4:?content required}")"
    sqlite3 "$DB_PATH" \
      "INSERT INTO messages (sender, recipient, content) VALUES ('$sender', '$recipient', '$content');
       UPDATE agents SET last_seen=CURRENT_TIMESTAMP WHERE name='$sender';"
    ;;
  create_proposal)
    proposer="$(sq "${2:?proposer required}")"
    title="$(sq "${3:?title required}")"
    content="$(sq "${4:?content required}")"
    sqlite3 "$DB_PATH" \
      "INSERT INTO proposals (proposer, title, content) VALUES ('$proposer', '$title', '$content');"
    ;;
  vote)
    reviewer="$(sq "${2:?reviewer required}")"
    proposal_id="${3:?proposal_id required}"
    vote="${4:?vote required}"
    comment="$(sq "${5:-}")"
    if [[ "$vote" != "APPROVE" && "$vote" != "REJECT" ]]; then
      echo "vote must be APPROVE or REJECT" >&2; exit 1
    fi
    sqlite3 "$DB_PATH" \
      "INSERT INTO reviews (proposal_id, reviewer, vote, comment) VALUES ($proposal_id, '$reviewer', '$vote', '$comment');" || exit 1
    ;;
  review_artifact)
    reviewer="$(sq "${2:?reviewer required}")"
    filename_raw="$(basename -- "${3:?filename required}")"
    filename="$(sq "$filename_raw")"
    vote="${4:?vote required}"
    comment="$(sq "${5:-}")"
    if [[ "$vote" != "APPROVE" && "$vote" != "REJECT" ]]; then
      echo "vote must be APPROVE or REJECT" >&2; exit 1
    fi
    sqlite3 "$DB_PATH" \
      "INSERT INTO artifact_reviews (filename, reviewer, vote, comment) VALUES ('$filename', '$reviewer', '$vote', '$comment');" || exit 1
    ;;
  *)
    usage
    ;;
esac
