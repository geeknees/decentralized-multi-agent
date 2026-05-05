# Evaluation Plan

This plan defines how to evaluate the decentralized blackboard prototype without overstating current evidence.

## Goals

- Measure whether peer agents can complete missions through shared blackboard coordination.
- Compare decentralized coordination against simpler and more centralized baselines.
- Identify failure modes and governance rules that matter.
- Produce reproducible logs suitable for a Zenodo release.

## Metrics

| Metric | Definition | Source |
|---|---|---|
| Task completion rate | Fraction of runs that reach a declared completed state or satisfy the artifact rubric | `mission_state`, artifact review, human rubric |
| Time to decision | Wall-clock time from run start to first `DECIDED` proposal | run log, SQLite timestamps |
| Messages until decision | Number of messages before first `DECIDED` proposal | `messages`, `proposals` |
| Number of proposals | Total proposals created per run | `proposals` |
| Approve/reject ratio | `APPROVE` votes divided by total votes | `reviews`, `artifact_reviews` |
| Duplicate vote prevention | Whether duplicate votes are rejected and logged as expected | tests, run errors |
| Artifact acceptance rate | Fraction of generated artifacts accepted by review | `artifact_reviews`, human rubric |
| Human intervention points | Count and type of manual interventions | experiment log |
| Failure cases | Labeled failure modes per run | experiment log and post-run analysis |
| Token cost | Input/output tokens and cost per run | provider logs or wrapper instrumentation |
| Wall-clock time | Start-to-finish elapsed time | experiment log |
| Reproducibility of runs | Ability to rerun with same commit, prompt, and settings and obtain comparable outcomes | repeated runs |
| Final artifact quality | Human-rated score against a fixed rubric | blinded human review where possible |

## Baselines

### Single-Agent Baseline

One LLM agent receives the mission and produces the artifact directly. It may use the same artifact criteria but does not use peer proposals or voting.

Purpose: establish whether multi-agent overhead is justified.

### Central Manager-Agent Baseline

A manager agent assigns work to specialized agents, decides when to proceed, and accepts or rejects outputs.

Purpose: compare decentralized peer review with a common manager-worker design.

### Decentralized Blackboard Version

The current prototype: multiple agents share SQLite, create proposals, vote, write artifacts, and review artifacts.

Purpose: measure whether blackboard-mediated governance supports completion and review without a central manager.

### Human-in-the-Loop Version

The decentralized version with explicit human approval or intervention checkpoints.

Purpose: measure whether minimal human oversight reduces stalls, false acceptance, or unsafe actions.

## Experiment Matrix

| Variable | Suggested Values |
|---|---|
| Number of agents | 1, 2, 3, 5 |
| Decision threshold | 1 approval, 2 approvals, majority of active agents |
| Self-approval | allowed, forbidden, allowed but labeled |
| Mission complexity | simple summary, structured comparison, code-change task, source-grounded research task |
| Artifact review | disabled, peer review only, peer plus human review |
| Model/provider | TODO: record exact provider and model |
| Loop interval | 5s, 10s, 30s |

## Data Collection

Each run should preserve:

- experiment log from `experiment-log-template.md`;
- git commit hash;
- mission prompt;
- model/provider settings;
- exported conversation and peer-review logs;
- final artifact;
- test results for the commit used;
- token and wall-clock measurements;
- human rating sheet if quality is scored.

## Human Rating Rubric

For final artifact quality, use a 1-5 scale on:

- task coverage;
- factual accuracy;
- internal consistency;
- usefulness to target reader;
- evidence and source quality;
- clarity and structure;
- compliance with mission completion criteria.

Record reviewer identity or anonymized reviewer ID, date, and whether the reviewer saw the experimental condition.

## Analysis Plan

- Report descriptive statistics first.
- Avoid strong significance claims until enough repeated runs exist.
- Separate implementation failures from model reasoning failures.
- Treat token cost and wall-clock time as first-class outcomes, not only task quality.
- Include representative failure cases with database evidence.

## Minimum Zenodo-Ready Evaluation

For v0.1.0, a minimal acceptable evaluation package is:

- all tests passing at the release commit;
- at least one fresh sample run on the current schema;
- exported logs for that run;
- one completed experiment-log template;
- a short note stating that controlled baseline comparisons are future work.
