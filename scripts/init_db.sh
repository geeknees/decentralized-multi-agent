#!/usr/bin/env bash
# ABOUTME: Initializes the SQLite shared blackboard with all tables and triggers
# ABOUTME: Safe to re-run (uses CREATE IF NOT EXISTS)

set -euo pipefail

DB_PATH="${DB_PATH:-$(dirname "$0")/../db/collective.db}"
mkdir -p "$(dirname "$DB_PATH")"

sqlite3 "$DB_PATH" << 'SQL'
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
SQL

echo "Database initialized: $DB_PATH"
