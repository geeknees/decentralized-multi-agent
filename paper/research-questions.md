# Research Questions

This file defines research questions for the decentralized multi-agent prototype. The current repository can motivate these questions, but most of them require controlled experiments before strong claims can be made.

This prototype also helps organize practical challenges in realizing decentralized organizations with LLM agents. The current implementation addresses two narrow challenges: explicit decision phases, and explicit artifacts with acceptance criteria. It does not yet address whether an organization exists only for artifact production, or how non-artifact organizational purpose should be represented and evaluated.

## RQ1: Can LLM agents coordinate through a shared blackboard without a central orchestrator?

### Background

The implementation gives each agent the same loop and a shared SQLite blackboard. Agents read unread messages, proposals, mission state, and artifact reviews, then write JSON actions back to the database. There is no permanent manager agent that routes or assigns tasks.

### Indicators to Observe

- task completion rate;
- number of messages before first proposal;
- number of proposals before first decision;
- number of role changes;
- number of stalled runs;
- wall-clock time to completion;
- human interventions required.

### Experiment Method

Run the same mission across three conditions: single agent, central manager-agent, and decentralized blackboard. Use the same model/provider, temperature where configurable, mission prompt, and artifact completion criteria. Repeat each condition enough times to observe variance.

### What Can Be Said Now

The implementation supports blackboard-mediated coordination at the mechanism level. The sample mission shows agents exchanging messages and proposals through SQLite.

### What Cannot Be Said Yet

It is not yet established that blackboard coordination is more reliable, faster, cheaper, or higher quality than central orchestration.

## RQ2: Does a proposal-and-review protocol reduce premature convergence or unilateral decisions?

### Background

The current protocol requires two approvals before a proposal becomes `DECIDED`. Rejecting agents are instructed to provide alternatives. Duplicate votes by the same agent are blocked with a unique constraint. Proposal self-votes and artifact self-reviews are rejected by SQLite triggers.

### Indicators to Observe

- approve/reject ratio;
- number of rejected proposals later replaced by improved proposals;
- number of unilateral actions before approval;
- proposal churn;
- artifact quality after accepted proposals;
- diversity of reviewers per decision.

### Experiment Method

Compare runs with no proposal protocol, one-approval protocol, two-approval protocol, and two-approval with proposal self-vote prevention. Use tasks where premature convergence can be detected through an external rubric.

### What Can Be Said Now

The implementation prevents duplicate votes, proposal self-votes, and artifact self-reviews, and atomically marks a proposal as decided after two approvals. The sample peer-review log includes a rejected proposal with a concrete replacement structure.

### What Cannot Be Said Yet

The repository does not yet prove that this protocol improves final artifacts or reduces premature convergence. It may also increase latency and message count.

## RQ3: What kinds of failures occur in decentralized LLM-agent coordination?

### Background

Decentralized coordination removes a central scheduler and therefore needs other mechanisms for convergence, conflict handling, and artifact acceptance.

### Indicators to Observe

- stalled runs;
- repeated or overlapping proposals;
- inconsistent role coverage;
- invalid self-vote attempts;
- invalid artifact self-review attempts;
- invalid JSON or empty action rate;
- rejected artifacts and revision count;
- hallucinated or unverifiable factual claims;
- token and wall-clock overruns.

### Experiment Method

Run missions with increasing ambiguity and complexity. Label failures from database logs and generated artifacts. Separate protocol failures, model-output failures, implementation failures, and evaluation failures.

### What Can Be Said Now

The sample run and implementation review suggest likely failures: proposal churn, role duplication, invalid self-vote attempts, invalid artifact self-review attempts, long discussions, and prompt-level rule drift.

### What Cannot Be Said Yet

There is no failure taxonomy backed by repeated runs. Current observations are not enough to estimate failure frequency.

## RQ4: What minimum governance rules are needed for task completion and artifact review?

### Background

The prototype includes minimal governance: mission document, action schema, two-approval decision threshold, duplicate-vote prevention, proposal self-vote prevention, artifact-review lifecycle, artifact self-review prevention, and rejection-based reopening.

### Indicators to Observe

- completion rate under different governance settings;
- artifact acceptance rate;
- number of artifact rewrites;
- number of decisions later contradicted;
- human interventions;
- invalid or unsafe actions;
- reviewer coverage.

### Experiment Method

Ablate governance features one by one: remove duplicate vote prevention, disable proposal self-vote prevention, disable artifact self-review prevention, allow one-approval decisions, remove artifact review, remove rejection alternatives, and add quorum. Compare completion and quality.

### What Can Be Said Now

The current implementation demonstrates a small set of enforceable rules in SQLite plus additional prompt-level rules in `agents/CLAUDE.md`.

### What Cannot Be Said Yet

The minimum necessary governance set is unknown. Some current rules may be insufficient, and some may be unnecessary for simple tasks.

## RQ5: How does this architecture compare with manager-worker or centrally orchestrated agent systems?

### Background

Frameworks such as AutoGen, CrewAI, and LangGraph support multi-agent workflows, often through explicit orchestration, manager patterns, graph routing, flows, or handoffs. This project instead emphasizes peer agents acting through a shared blackboard and database-level decision transitions.

### Indicators to Observe

- task completion rate;
- final artifact quality;
- time to first useful artifact;
- number of manager/router decisions;
- number of peer-review decisions;
- token cost;
- reproducibility;
- explainability of decision history;
- ease of human intervention.

### Experiment Method

Implement comparable tasks in a central manager-agent setup and in the decentralized blackboard setup. Keep model/provider and mission rubric consistent. Compare logs, costs, artifacts, and human-rated quality.

### What Can Be Said Now

The architectural difference is clear at the implementation level: this prototype has no standing manager agent and persists governance events in SQLite.

### What Cannot Be Said Yet

No empirical comparison has been completed. It is not yet known whether the decentralized version is better for any specific task class.

## RQ6: How should decentralized LLM-agent organizations represent purpose beyond artifact production?

### Background

The current prototype makes missions, phases, artifacts, and review criteria explicit. This is enough to run bounded experiments and produce auditable outputs. It is not enough to model an organization whose existence is not reducible to producing a specified deliverable.

### Indicators to Observe

- whether agents can maintain a stable purpose across multiple missions;
- whether decisions preserve stated values when no artifact is immediately produced;
- how agents handle maintenance, learning, onboarding, and reflection tasks;
- whether non-artifact outcomes can be logged and reviewed without becoming vague;
- how humans judge organizational coherence across runs.

### Experiment Method

Design multi-mission runs where some phases do not require artifact production. Compare artifact-centered missions with purpose-centered missions that include maintenance, retrospective, policy revision, or member-role evolution. Require logs for decisions that preserve or reinterpret organizational purpose.

### What Can Be Said Now

The prototype can encode a mission document and phase table, and it can force agents to make artifacts and reviews explicit. This helps clarify two organizational mechanics: decision timing and deliverable acceptance.

### What Cannot Be Said Yet

The repository does not yet define or evaluate organizational existence beyond artifacts. It cannot currently test whether decentralized agents sustain identity, values, learning, or purpose across changing tasks.
