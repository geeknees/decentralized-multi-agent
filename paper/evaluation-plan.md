# Evaluation Plan

This plan describes how to evaluate the decentralized blackboard prototype without overstating the evidence.

## Goals

- Measure whether peer agents can complete missions through shared blackboard coordination.
- Compare decentralized coordination against simpler and more centralized baselines.
- Identify failure modes and governance rules that matter.
- Produce reproducible logs suitable for a Zenodo release.
- Separate artifact-production success from organizational-purpose questions.

## Metrics

| Metric | Definition | Source |
|---|---|---|
| Task completion rate | Fraction of runs that reach a declared completed state or satisfy the artifact rubric | `mission_state`, artifact review, human rubric |
| Time to decision | Wall-clock time from run start to first `DECIDED` proposal | run log, SQLite timestamps |
| Messages until decision | Number of messages before first `DECIDED` proposal | `messages`, `proposals` |
| Number of proposals | Total proposals created per run | `proposals` |
| Approve/reject ratio | `APPROVE` votes divided by total votes | `reviews`, `artifact_reviews` |
| Duplicate vote prevention | Whether duplicate votes are rejected and no duplicate rows persist | tests, run errors, SQLite queries |
| Proposal self-vote prevention | Whether proposer votes are rejected and no self-vote rows persist | tests, run errors, SQLite queries |
| Artifact self-review prevention | Whether artifact author reviews are rejected and no self-review rows persist | tests, run errors, SQLite queries |
| Rejected governance attempts | Number of rejected duplicate votes, proposal self-votes, or artifact self-reviews, if explicit audit logging is enabled | future audit table or external process logs |
| Artifact acceptance rate | Fraction of generated artifacts accepted by review | `artifact_reviews`, human rubric |
| Human intervention points | Count and type of manual interventions | experiment log |
| Failure cases | Labeled failure modes per run | experiment log and post-run analysis |
| Token cost | Input/output tokens and cost per run | provider logs or wrapper instrumentation |
| Wall-clock time | Start-to-finish elapsed time | experiment log |
| Reproducibility of runs | Ability to rerun with same commit, prompt, and settings and obtain comparable outcomes | repeated runs |
| Final artifact quality | Human-rated score against a fixed rubric | blinded human review where possible |
| Purpose continuity | Whether agents preserve stated mission values across multiple tasks | multi-run logs, human rubric |

## Baselines

### Single-Agent Baseline

One LLM agent receives the mission and produces the artifact directly. It may use the same artifact criteria but does not use peer proposals or voting.

Purpose: check whether the extra multi-agent machinery is worth it.

### Central Manager-Agent Baseline

A manager agent assigns work to specialized agents, decides when to proceed, and accepts or rejects outputs.

Purpose: compare decentralized peer review with a common manager-worker design.

This baseline should not turn the project into a productivity benchmark. Manager-worker systems and frameworks such as AutoGen, CrewAI, and LangGraph usually focus on task decomposition, specialist routing, workflow reliability, and token or latency tradeoffs. Those are valid engineering concerns. This prototype asks a different question: can a decentralized peer model make exploratory progress when expertise, authority, or resources are incomplete or distributed?

### Decentralized Blackboard Version

The current prototype: multiple agents share SQLite, create proposals, vote, write artifacts, and review artifacts.

Purpose: measure whether blackboard-mediated governance supports completion and review without a central manager. Productivity and token cost are still recorded, but they are secondary metrics.

### Human-in-the-Loop Version

This condition can mean at least two things:

- **Embedded human checkpoints:** the software pauses at selected decision or artifact-review points and requires explicit human approval before continuing.
- **External human review:** the agent system produces artifacts, database logs, and exported Markdown records. Humans then review those outputs outside the core runtime. Separate LLM-based tools can help with rubrics, source checks, or comparison summaries.

Purpose: measure whether human oversight reduces stalls, false acceptance, unsafe actions, or low-quality artifacts.

For this technical-report release, Human-in-the-Loop is a proposed evaluation condition, not an implemented result. External review may compose better than human approval built into one runtime. It keeps the prototype focused on reproducible artifacts and logs, lets review workflows change independently, and makes the method easier to apply in education, political science, software engineering, and organization-theory studies.

## Experiment Matrix

| Variable | Suggested Values |
|---|---|
| Number of agents | 1, 2, 3, 5 |
| Decision threshold | 1 approval, 2 approvals, majority of active agents |
| Proposal self-vote prevention | enabled, disabled in ablation branch |
| Artifact self-review prevention | enabled, disabled in ablation branch |
| Mission complexity | simple summary, structured comparison, code-change task, source-grounded research task |
| Artifact review | disabled, peer review only, peer plus human review |
| Human oversight mode | none, embedded checkpoint, external artifact/log review, LLM-assisted external review |
| Model/provider | TODO: record exact provider and model |
| Provider adapter | claude, codex, ollama, openai-compatible, custom command |
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

For final artifact quality, use a 1-5 scale:

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
- Treat token cost and wall-clock time as outcomes, not just task quality.
- Include representative failure cases with database evidence.

## Minimum Zenodo-Ready Evaluation

For v0.1.0, the minimum evaluation package is:

- all tests passing at the release commit;
- at least one fresh sample run on the current schema;
- exported logs for that run;
- one completed experiment-log template;
- a short note stating that controlled baseline comparisons are future work.
