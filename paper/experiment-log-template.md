# Experiment Log Template

Copy this template once per run. Store completed logs under a versioned directory such as `experiments/2026-05-05-exp-001/` if experiment logs are added to the repository.

## Experiment Metadata

| Field | Value |
|---|---|
| Experiment ID | TODO |
| Date | TODO |
| Researcher/operator | TODO |
| Git commit hash | TODO |
| Repository URL | https://github.com/geeknees/decentralized-multi-agent |
| Version/tag | TODO |
| Machine/OS | TODO |

## Model and Runtime

| Field | Value |
|---|---|
| Model/provider | TODO |
| Provider adapter | TODO |
| Endpoint, if local/API provider | TODO |
| Model version or release date | TODO |
| Temperature / sampling settings | TODO |
| Number of agents | TODO |
| Agent names | TODO |
| Loop interval | TODO |
| Max loops, if any | TODO |
| Token accounting method | TODO |

## Mission

### Mission Prompt

```text
TODO
```

### Initial Conditions

- Initial database state: TODO
- Initial `purpose_doc.md`: TODO
- Predefined roles: TODO
- Decision threshold: TODO
- Artifact completion criteria: TODO
- Human intervention policy: TODO
- Human oversight mode: none / embedded checkpoint / external artifact-log review / LLM-assisted external review

## Final State

| Field | Value |
|---|---|
| Final mission state | TODO |
| Completed at | TODO |
| Final artifact filename(s) | TODO |
| Final artifact accepted? | TODO |
| Run completed without human intervention? | TODO |
| Post-run human review completed? | TODO |
| LLM-assisted review used? | TODO |

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
| Post-run human reviewers | TODO |
| Wall-clock time | TODO |
| Token cost | TODO |
| Estimated monetary cost | TODO |

## Artifact Outputs

| Artifact | Path | Notes |
|---|---|---|
| TODO | TODO | TODO |

## Human Interventions

| Time | Intervention | Reason | Effect |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## External Human Review

Use this section when the run itself is not interrupted by a human, but generated artifacts and logs are reviewed after completion. This can include ordinary human review or review augmented by separate LLM tools. Record the review method separately from agent-runtime behavior.

| Reviewer ID | Reviewed material | Method | LLM assistance used? | Outcome | Notes |
|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO |

## Failure Modes

Check all that apply and add evidence.

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
  - TODO

- Steps needed to reproduce:
  - TODO
