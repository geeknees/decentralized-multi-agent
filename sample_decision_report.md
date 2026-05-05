# ABOUTME: Technical note on the SQLite-trigger-based governance design decision
# ABOUTME: Covers problem, mechanism, expected benefit, limitations, and one future improvement

# SQLite Trigger–Based Governance in the Decentralized Multi-Agent System

## Problem

In a leaderless multi-agent system, governance rules—no self-votes, no self-reviews, quorum-based proposal decisions, and automatic mission-state transitions—must be enforced without relying on any single agent's correct behavior or honesty. Agent code paths can contain bugs or omissions, and there is no central coordinator to arbitrate disputes. If governance logic lives only in application code, any misbehaving or malfunctioning agent can break invariants silently.

## Implemented Mechanism

`scripts/init_db.sh` installs five SQLite triggers on the shared database:

| Trigger | Table | Event | Effect |
|---------|-------|-------|--------|
| `prevent_self_vote` | `reviews` | BEFORE INSERT | Aborts any INSERT where the reviewer is the proposal's own proposer |
| `prevent_artifact_self_review` | `artifact_reviews` | BEFORE INSERT | Aborts any INSERT where the reviewer is the artifact's author |
| `auto_decide` | `reviews` | AFTER INSERT | Sets proposal status to `DECIDED` when ≥ 2 APPROVE votes accumulate |
| `auto_complete_mission` | `artifact_reviews` | AFTER INSERT | Transitions `mission_state` to `completed` when the artifact receives ≥ 2 APPROVEs |
| `auto_reopen_mission` | `artifact_reviews` | AFTER INSERT | Reverts `mission_state` to `running` on any REJECT of the current artifact |

The two blocking triggers use `RAISE(ABORT, ...)`, which rolls back the entire offending transaction atomically before any row is written.

## Expected Benefit

Governance invariants are enforced at the database layer, outside all agent code paths. No agent can bypass them through a bug or deliberate omission. Because `RAISE(ABORT)` rolls back the transaction, partial writes cannot corrupt governance state. All agents share a single consistent view of proposal and mission status simply by reading the same SQLite file—no message-passing protocol or consensus round is required.

## Limitations

- **Single-host only.** SQLite is a local file; it provides no distributed consensus across separate machines. All agents must run on the same host to share the database.
- **Schema evolution is manual.** The trigger and schema definitions are embedded in `scripts/init_db.sh` as a `DROP TRIGGER IF EXISTS` / `CREATE TRIGGER` block. Adding or changing a trigger requires editing the shell script and re-running initialization, with no record of what changed or when.
- **Concurrency under load.** Concurrent writes require WAL mode and careful `busy_timeout` tuning; without these, simultaneous agent writes can produce `SQLITE_BUSY` errors that the caller must retry.

## One Future Improvement

Extract the trigger and schema definitions from `scripts/init_db.sh` into versioned SQL migration files (e.g., `db/migrations/001_initial_schema.sql`, `db/migrations/002_governance_triggers.sql`). A lightweight migration runner applied at startup would record which migrations have been applied, allowing schema evolution to be tracked in version control, reviewed in pull requests, and tested independently of the shell initialization script—without abandoning SQLite or requiring a server process.
