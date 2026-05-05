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
| Machine/OS | TODO: fill after run |

## Model and Runtime

| Field | Value |
|---|---|
| Model/provider | TODO: choose before run |
| Provider adapter | TODO: `claude`, `codex`, `ollama`, `openai-compatible`, or custom |
| Endpoint, if local/API provider | TODO |
| Model version or release date | TODO |
| Temperature / sampling settings | TODO |
| Number of agents | 3 |
| Agent names | `agent-alpha`, `agent-beta`, `agent-gamma` |
| Loop interval | TODO |
| SQLite busy timeout | TODO |
| Max loops, if any | TODO |
| Token accounting method | TODO |

## Mission

### Mission Prompt

See `purpose_doc.md` in this directory.

### Initial Conditions

- Initial database state: TODO: fresh database initialized with current schema.
- Initial `purpose_doc.md`: `experiments/2026-05-05-v0.1.0-sample/purpose_doc.md`.
- Predefined roles: none; agents self-select from the mission's Available Roles.
- Decision threshold: two `APPROVE` votes for proposals; proposal self-votes rejected.
- Artifact completion criteria: `sample_decision_report.md` includes problem, mechanism, expected benefit, limitations, and one future improvement.
- Human intervention policy: TODO.

## Final State

| Field | Value |
|---|---|
| Final mission state | TODO |
| Completed at | TODO |
| Final artifact filename(s) | `sample_decision_report.md` |
| Final artifact accepted? | TODO |
| Run completed without human intervention? | TODO |

## Quantitative Summary

| Metric | Value |
|---|---|
| Number of messages | TODO |
| Number of proposals | TODO |
| Number of decided proposals | TODO |
| Number of approvals | TODO |
| Number of rejections | TODO |
| Artifact review approvals | TODO |
| Artifact review rejections | TODO |
| Duplicate vote attempts | TODO |
| Proposal self-vote attempts | TODO |
| Artifact self-review attempts | TODO |
| Human interventions | TODO |
| Wall-clock time | TODO |
| Token cost | TODO |
| Estimated monetary cost | TODO |

## Artifact Outputs

| Artifact | Path | Notes |
|---|---|---|
| `sample_decision_report.md` | TODO | Final artifact from the sample run |
| `whole_conversation_doc.md` | TODO | Exported conversation log |
| `peer_review_doc.md` | TODO | Exported decision and artifact review log |

## Human Interventions

| Time | Intervention | Reason | Effect |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## Failure Modes

- [ ] Proposal churn
- [ ] Role duplication
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
- [ ] Other: TODO

### Evidence

```text
TODO
```

## Notes

TODO

## Reproducibility Notes

- Exact commands used:

```bash
TODO
```

- Files archived:
  - TODO

- Known non-determinism:
  - LLM outputs may vary across runs unless using a deterministic local provider and fixed settings.

- Steps needed to reproduce:
  - TODO
