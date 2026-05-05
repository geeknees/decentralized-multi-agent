#!/usr/bin/env bash
# ABOUTME: Initializes the SQLite shared blackboard with all tables and triggers
# ABOUTME: Safe to re-run (uses CREATE IF NOT EXISTS)

set -euo pipefail

DB_PATH="${DB_PATH:-$(dirname "$0")/../db/collective.db}"
SQLITE_BUSY_TIMEOUT_MS="${SQLITE_BUSY_TIMEOUT_MS:-5000}"
mkdir -p "$(dirname "$DB_PATH")"

sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT_MS" "$DB_PATH" << 'SQL'
CREATE TABLE IF NOT EXISTS agents (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT UNIQUE NOT NULL,
  role         TEXT,
  status       TEXT DEFAULT 'active',
  last_seen    DATETIME DEFAULT CURRENT_TIMESTAMP,
  last_read_id INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS messages (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  sender     TEXT NOT NULL,
  recipient  TEXT DEFAULT 'ALL',
  content    TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS proposals (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  proposer   TEXT NOT NULL,
  title      TEXT NOT NULL,
  content    TEXT NOT NULL,
  status     TEXT DEFAULT 'OPEN',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS reviews (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  proposal_id INTEGER REFERENCES proposals(id),
  reviewer    TEXT NOT NULL,
  vote        TEXT NOT NULL,
  comment     TEXT,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(proposal_id, reviewer)
);

CREATE TABLE IF NOT EXISTS mission_state (
  id                  INTEGER PRIMARY KEY CHECK (id = 1),
  status              TEXT NOT NULL DEFAULT 'running'
                        CHECK (status IN ('running', 'review', 'completed')),
  artifact_filename   TEXT,
  artifact_author     TEXT,
  artifact_written_at DATETIME,
  completed_at        DATETIME,
  updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS artifact_reviews (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  filename   TEXT NOT NULL,
  reviewer   TEXT NOT NULL,
  vote       TEXT NOT NULL CHECK (vote IN ('APPROVE', 'REJECT')),
  comment    TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(filename, reviewer)
);

INSERT OR IGNORE INTO mission_state (id, status) VALUES (1, 'running');
SQL

if ! sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT_MS" "$DB_PATH" "PRAGMA table_info(mission_state);" \
  | awk -F'|' '$2 == "artifact_author" { found = 1 } END { exit(found ? 0 : 1) }'; then
  sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT_MS" "$DB_PATH" "ALTER TABLE mission_state ADD COLUMN artifact_author TEXT;"
fi

sqlite3 -cmd ".timeout $SQLITE_BUSY_TIMEOUT_MS" "$DB_PATH" << 'SQL'

DROP TRIGGER IF EXISTS prevent_self_vote;
DROP TRIGGER IF EXISTS prevent_artifact_self_review;
DROP TRIGGER IF EXISTS auto_complete_mission;
DROP TRIGGER IF EXISTS auto_reopen_mission;

CREATE TRIGGER IF NOT EXISTS prevent_self_vote
BEFORE INSERT ON reviews
WHEN NEW.reviewer = (SELECT proposer FROM proposals WHERE id = NEW.proposal_id)
BEGIN
  SELECT RAISE(ABORT, 'proposal proposer cannot vote on their own proposal');
END;

CREATE TRIGGER IF NOT EXISTS prevent_artifact_self_review
BEFORE INSERT ON artifact_reviews
WHEN NEW.reviewer = (SELECT artifact_author FROM mission_state
                     WHERE id = 1 AND artifact_filename = NEW.filename)
BEGIN
  SELECT RAISE(ABORT, 'artifact author cannot review their own artifact');
END;

CREATE TRIGGER IF NOT EXISTS auto_decide
AFTER INSERT ON reviews
WHEN NEW.vote = 'APPROVE'
BEGIN
  UPDATE proposals
  SET status = 'DECIDED'
  WHERE id = NEW.proposal_id
    AND (SELECT COUNT(*) FROM reviews
         WHERE proposal_id = NEW.proposal_id AND vote = 'APPROVE') >= 2;
END;

CREATE TRIGGER IF NOT EXISTS auto_complete_mission
AFTER INSERT ON artifact_reviews
WHEN NEW.vote = 'APPROVE'
BEGIN
  UPDATE mission_state
  SET status = 'completed',
      completed_at = CURRENT_TIMESTAMP,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = 1
    AND artifact_filename = NEW.filename
    AND status = 'review'
    AND (SELECT COUNT(*) FROM artifact_reviews
         WHERE filename = NEW.filename AND vote = 'APPROVE') >= 2;
END;

CREATE TRIGGER IF NOT EXISTS auto_reopen_mission
AFTER INSERT ON artifact_reviews
WHEN NEW.vote = 'REJECT'
BEGIN
  UPDATE mission_state
  SET status = 'running',
      completed_at = NULL,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = 1
    AND artifact_filename = NEW.filename
    AND status = 'review';
END;
SQL

echo "Database initialized: $DB_PATH"
