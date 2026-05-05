# Experiment Log: 2026-05-05-v0.1.0-sample

## Experiment Metadata

| Field | Value |
|---|---|
| Experiment ID | 2026-05-05-v0.1.0-sample |
| Date | 2026-05-05 JST |
| Researcher/operator | Masumi Kawasaki |
| Git commit hash | 05e60c6f5fe3aac2c105ebd8d019fe3d9445c8b3 plus local release-prep changes |
| Repository URL | https://github.com/geeknees/decentralized-multi-agent |
| Version/tag | v0.1.0 candidate |
| Machine/OS | macOS Darwin 25.4.0 arm64 |

## Model and Runtime

| Field | Value |
|---|---|
| Model/provider | Claude Code CLI |
| Provider adapter | `claude` |
| Endpoint, if local/API provider | Not applicable |
| Model version or release date | Claude Code 2.1.126 |
| Temperature / sampling settings | Provider default; not explicitly configured |
| Number of agents | 3 |
| Agent names | `agent-alpha`, `agent-beta`, `agent-gamma` |
| Loop interval | 10 seconds |
| SQLite busy timeout | 10000 ms |
| Max loops, if any | none |
| Token accounting method | Not captured in this run |

## Mission

### Mission Prompt

See `purpose_doc.md` in this directory.

### Initial Conditions

- Initial database state: fresh `db/collective.db` initialized with current schema before launch.
- Initial `purpose_doc.md`: `experiments/2026-05-05-v0.1.0-sample/purpose_doc.md`.
- Predefined roles: none; agents self-select from the mission's Available Roles.
- Decision threshold: two `APPROVE` votes for proposals; proposal self-votes rejected.
- Artifact completion criteria: `sample_decision_report.md` includes problem, mechanism, expected benefit, limitations, and one future improvement.
- Human intervention policy: no in-run intervention; operator only launched and later archived outputs.

## Final State

| Field | Value |
|---|---|
| Final mission state | `completed` |
| Completed at | 2026-05-05 04:12:24 UTC / 2026-05-05 13:12:24 JST |
| Final artifact filename(s) | `sample_decision_report.md` |
| Final artifact accepted? | yes, two artifact `APPROVE` votes |
| Run completed without human intervention? | yes |

## Quantitative Summary

| Metric | Value |
|---|---|
| Number of messages | 20 |
| Number of proposals | 5 |
| Number of decided proposals | 3 |
| Number of approvals | 8 proposal approvals |
| Number of rejections | 2 proposal rejections |
| Artifact review approvals | 2 |
| Artifact review rejections | 0 |
| Duplicate vote attempts | 0 observed |
| Proposal self-vote attempts | 0 persisted; DB query found 0 self-vote rows |
| Artifact self-review attempts | 0 persisted; DB query found 0 self-review rows |
| Human interventions | 0 during run |
| Wall-clock time | approximately 8 minutes 22 seconds from first to last message |
| Token cost | Not captured |
| Estimated monetary cost | Not captured |

## Artifact Outputs

| Artifact | Path | Notes |
|---|---|---|
| `sample_decision_report.md` | `experiments/2026-05-05-v0.1.0-sample/sample_decision_report.md` | Final artifact from the sample run |
| `whole_conversation_doc.md` | `experiments/2026-05-05-v0.1.0-sample/whole_conversation_doc.md` | Exported conversation log |
| `peer_review_doc.md` | `experiments/2026-05-05-v0.1.0-sample/peer_review_doc.md` | Exported decision and artifact review log |
| `collective.sql` | `experiments/2026-05-05-v0.1.0-sample/collective.sql` | SQL dump of the run database |

## Human Interventions

| Time | Intervention | Reason | Effect |
|---|---|---|---|
| None | None | Not applicable | Not applicable |

## Failure Modes

- [x] Proposal churn
- [x] Role duplication
- [ ] Proposal self-vote attempt
- [ ] Artifact self-review
- [ ] Duplicate vote attempt
- [ ] Invalid JSON
- [ ] Empty or no-op action loop
- [ ] Artifact rejected
- [ ] Mission stalled
- [ ] Factual hallucination
- [ ] Source verification failure
- [ ] Token/cost overrun
- [ ] Human intervention required
- [ ] Other

### Evidence

```text
Proposal churn: 5 proposals were created for a small artifact. Proposals #1, #2, and #5 reached DECIDED; #3 and #4 remained OPEN.
Role duplication: final agent roles were agent-alpha=Researcher, agent-beta=Proposer, agent-gamma=Researcher.
No persisted proposal self-vote rows, artifact self-review rows, or duplicate proposal votes were found in SQLite.
```

## Notes

The final artifact satisfied the declared completion criteria and was accepted by two reviewers. The run also surfaced a useful governance behavior: agents rejected broader future-work suggestions and converged on a SQLite-compatible improvement. The run did not capture token usage or model sampling settings.

## Reproducibility Notes

- Exact commands used:

```bash
cp experiments/2026-05-05-v0.1.0-sample/purpose_doc.md purpose_doc.md
rm -f db/collective.db sample_decision_report.md whole_conversation_doc.md peer_review_doc.md
LLM_PROVIDER=claude SQLITE_BUSY_TIMEOUT_MS=10000 LOOP_INTERVAL=10 \
  scripts/launch.sh agent-alpha agent-beta agent-gamma
```

- Files archived:
  - `experiments/2026-05-05-v0.1.0-sample/purpose_doc.md`
  - `experiments/2026-05-05-v0.1.0-sample/purpose_doc.used.md`
  - `experiments/2026-05-05-v0.1.0-sample/sample_decision_report.md`
  - `experiments/2026-05-05-v0.1.0-sample/whole_conversation_doc.md`
  - `experiments/2026-05-05-v0.1.0-sample/peer_review_doc.md`
  - `experiments/2026-05-05-v0.1.0-sample/collective.sql`

- Known non-determinism:
  - LLM outputs may vary across runs unless using a deterministic local provider and fixed settings.

- Steps needed to reproduce:
  - Ensure Claude Code CLI is installed and authenticated.
  - Run the exact commands above from the repository root.
  - Wait until `mission_state.status` becomes `completed`.
  - Export or copy the generated artifact and Markdown logs.
