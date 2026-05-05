# Decentralized Multi-Agent System: A Blackboard-Based Peer Review Architecture for LLM Agents

## Abstract

This technical report describes a research prototype for decentralized coordination among large language model agents. The system runs several agent processes as independent `tmux` sessions. Each agent reads a shared SQLite database, receives the mission and current blackboard state, calls a configurable LLM provider adapter, and writes JSON actions back to the database. There is no manager agent that assigns tasks or approves work. Instead, agents create proposals, vote `APPROVE` or `REJECT`, and SQLite triggers mark a proposal as decided after two approvals. A separate artifact-review path moves a mission from running, to review, to completed after two artifact approvals.

The prototype asks whether a small set of database-backed governance rules can support task progress, dissent, revision, and final artifact acceptance among peer LLM agents. It is closer to a blackboard architecture and a small social-system experiment than to a productivity benchmark for orchestration frameworks. Evidence is still thin: implementation tests and one small sample mission. For that reason, the report separates implementation, preliminary observations, failure modes, limitations, and an evaluation plan.

## 1. Introduction

This repository implements a small decentralized multi-agent system for LLM agents. The implementation goal is narrow: several independent agents coordinate through shared state, record their discussion, propose decisions, vote, produce an artifact, and review it without a standing manager agent.

The prototype is not a peer-reviewed result. It is a working-paper artifact meant to make the design inspectable and reproducible. The contribution at this stage is the design and executable reference implementation, not a claim that decentralized LLM-agent governance outperforms existing orchestration systems.

The implementation uses:

- `tmux` to run multiple agent loops as separate OS processes;
- SQLite as a shared blackboard and transactional decision log;
- shell scripts for process orchestration and database writes;
- Ruby for JSON extraction and action execution;
- Markdown exports for human inspection of conversation and peer-review history;
- tests for schema initialization, voting constraints, export formatting, agent startup, and mission completion flow.

## 2. Motivation

Many LLM-agent systems use a central controller. A manager, planner, router, graph node, or workflow engine decides which specialized agent acts next. That is often the right engineering choice. Central control is easier to debug, routing is explicit, and operators know where to intervene.

No empirical comparison with AutoGen, CrewAI, LangGraph, or similar frameworks is included here. The report should not be read as a productivity contest. Those tools usually help teams coordinate specialist agents, route work, and make task execution more efficient. Productivity, reliability, latency, and token cost matter there. This prototype starts from a different question: can autonomous peers make exploratory progress when expertise, authority, or resources are incomplete or spread across the group? It may turn out to help with productivity in some domains, but that is not the main point here.

The narrower design question is: what is the minimum machinery needed for LLM agents to coordinate as peers through shared state? The aim is not to replace centralized orchestration in production systems. It is to study a coordination pattern where:

- no agent has permanent authority over the others;
- the mission document acts as the shared constitution;
- decisions become durable only through peer approval;
- objections are stored as review events;
- final artifacts require a review step separate from ordinary discussion.

The implementation also exposes some practical problems in building decentralized organizations with LLM agents. It addresses two of them: explicit decision phases, and explicit artifacts with acceptance criteria. Those are useful primitives, but not enough for a theory of organization. An organization may not exist only to produce artifacts. Purpose, identity, learning, membership, and values remain outside the current implementation.

The prototype is also a small case study in using LLMs for organization-theory research. Whether agents can finish a task is only part of the question. The more interesting question is whether concepts such as authority, quorum, dissent, deliverables, and review can be encoded well enough to inspect. Similar methods could later be tried outside software-agent coordination. Education research, for example, might use LLM-supported simulation or analysis to study teacher-to-learner ratios and learning outcomes, but only with real educational assumptions, data, and validation. Political-science work might use similar methods for exploratory voting-behavior models. None of that is evaluated here.

This connects to blackboard systems, peer review, lightweight governance, and decentralized organizational design. The technical claim is narrower: this is an executable blackboard and decision protocol for LLM agents, not a theory of decentralized organizations.

## 3. System Overview

The runtime has N agent processes. Each process runs the same loop in `agents/agent.sh` and gets a distinct `AGENT_NAME`. The loop reads the mission from `purpose_doc.md`, reads unread messages and open proposals from SQLite, sends a structured prompt to `scripts/llm_call.sh`, extracts JSON actions, and applies them to the database or filesystem. The adapter supports Claude, Codex, Ollama, custom stdin/stdout commands, and OpenAI-compatible chat-completions endpoints.

The implemented action types are:

- `set_role`: update the agent's self-selected role;
- `post_message`: write a message to the blackboard;
- `create_proposal`: open a proposal for peer review;
- `vote`: approve or reject a proposal;
- `write_artifact`: write a complete artifact file and move the mission into review;
- `review_artifact`: approve or reject the generated artifact.

The system exports two Markdown logs from SQLite:

- `whole_conversation_doc.md`: chronological message log;
- `peer_review_doc.md`: proposal, review, and mission-review log.

Runtime database files and generated logs are ignored by default. For reproducible releases, selected run logs should be copied into a sample directory with experiment metadata.

## 4. Architecture

The system is a blackboard-style architecture with LLM agents as knowledge sources and SQLite as the shared blackboard. Agents do not communicate through direct process-to-process messages. They communicate by reading and writing shared database tables.

The main tables in the current schema are:

- `agents`: agent identity, self-selected role, status, and read position;
- `messages`: chronological conversation events;
- `proposals`: proposed decisions and their current status;
- `reviews`: proposal-level votes and comments;
- `mission_state`: mission lifecycle state for artifact review;
- `artifact_reviews`: artifact-level votes and comments.

The database also encodes part of the governance protocol. The `auto_decide` trigger marks a proposal as `DECIDED` once at least two `APPROVE` votes exist. The `auto_complete_mission` trigger marks a mission as `completed` when an artifact in review receives two approvals. The `auto_reopen_mission` trigger returns a mission to `running` when an artifact receives a rejection.

This differs from a conventional blackboard system in at least three ways:

- the knowledge sources are LLM-driven agent loops rather than fixed symbolic modules;
- the blackboard stores hypotheses, partial solutions, and governance events;
- decision state changes are partly enforced by database constraints and triggers rather than by a central scheduler.

## 5. Decision Protocol

The decision protocol is deliberately small:

1. An agent creates a proposal with a title and content.
2. Agents vote `APPROVE` or `REJECT`.
3. A proposal remains `OPEN` until two `APPROVE` votes are recorded.
4. A SQLite trigger changes the proposal status to `DECIDED`.
5. A unique constraint prevents the same agent from voting twice on the same proposal.
6. A SQLite trigger rejects proposal self-votes where the proposer and reviewer are the same agent.
7. Agent instructions require each rejection comment to include an alternative.

The protocol does not currently enforce every social rule at the database level. For example, the database prevents duplicate proposal votes and proposal self-votes, but the requirement that `REJECT` include an alternative is prompt-level guidance, not a schema-level invariant.

Artifact review uses a related but separate protocol:

1. An agent writes a complete artifact with `write_artifact`.
2. The mission enters `review` state and stale artifact reviews for that file are cleared.
3. Reviewers vote `APPROVE` or `REJECT` on the artifact.
4. Two approvals complete the mission.
5. One rejection reopens the mission for revision.
6. A unique constraint prevents the same agent from reviewing the same artifact twice per artifact version.
7. A SQLite trigger rejects artifact reviews by the agent that wrote the current artifact version.

The distinction matters. A proposal records agreement about what to do. Artifact review records whether the output meets the completion criteria.

## 6. Implementation

The repository is a compact shell/Ruby prototype:

- `scripts/init_db.sh` creates the SQLite schema and triggers.
- `scripts/db_write.sh` is the write interface for messages, proposals, votes, and artifact reviews.
- `scripts/llm_call.sh` dispatches prompts to the configured LLM provider.
- `scripts/run_actions.rb` executes JSON actions returned by an LLM.
- `scripts/extract_json.rb` extracts the first JSON object from an LLM response.
- `agents/agent.sh` implements the agent loop.
- `scripts/export_docs.sh` renders Markdown inspection logs from SQLite.
- `scripts/launch.sh` starts a `tmux` session with one window per agent.
- `scripts/reset_purpose.sh` archives a previous mission and clears runtime state for a new mission.

The current test suite covers:

- schema creation and trigger presence;
- database write helper behavior;
- proposal decision semantics;
- duplicate proposal vote rejection;
- proposal self-vote rejection;
- artifact self-review rejection;
- LLM provider adapter dispatch;
- Markdown export formatting for pipes and multiline content;
- agent startup with a test provider executable placed on `PATH`;
- artifact write/review/completion behavior.

The tests use real SQLite and real shell/Ruby execution. They do not add a production mock mode. Some tests replace external provider executables through `PATH` to avoid live model calls while keeping the agent loop's process boundary intact.

## 7. Example Mission

The included mission in `purpose_doc.md` asks agents to write a short technical note about one design decision in this repository: using SQLite triggers to enforce peer-review governance rules. The curated sample run is archived under `experiments/2026-05-05-v0.1.0-sample/`. It produced `sample_decision_report.md`, plus exported conversation, peer-review logs, and a SQL dump of the run database.

The generated peer-review log records a few useful events from the current schema:

- five proposals were created for a small artifact, showing proposal churn;
- three proposals reached `DECIDED` after two `APPROVE` votes;
- two proposals remained `OPEN`;
- the final artifact entered `review` state after `write_artifact`;
- two non-author agents approved the artifact, which moved the mission to `completed`;
- no persisted duplicate proposal votes, proposal self-votes, or artifact self-reviews were found in the archived SQLite dump.

This is still only a single run. It should be treated as an inspectable example of the implementation, not as evidence that the protocol improves output quality or reliability.

## 8. Evaluation Plan

The next stage should use controlled runs, fixed prompts, recorded model/provider settings, and comparable baselines. The minimum comparison set should include:

- a single-agent baseline;
- a central manager-agent baseline;
- the decentralized blackboard version;
- a human-in-the-loop version or post-run human review condition.

Primary metrics should include task completion rate, time to decision, messages until decision, proposal count, approve/reject ratio, duplicate vote prevention, persisted invalid rows, artifact acceptance rate, human intervention points, token cost, wall-clock time, reproducibility across repeated runs, and human-rated artifact quality.

Human-in-the-Loop needs a careful definition. One option is embedded human control: the runtime pauses for approval at selected proposal or artifact-review points. Another option is external human review: the agents produce artifacts and auditable logs, and humans inspect those outputs outside the core software. The second approach may compose better. Review procedures can be swapped, domain experts can use their own tools, and LLM-assisted review can be added without turning the agent runtime into a review platform. In this report, Human-in-the-Loop is an evaluation direction, not a demonstrated contribution.

Experiments should vary:

- number of agents;
- role definitions;
- decision threshold;
- mission complexity;
- model/provider;
- whether proposal self-vote prevention is enabled;
- whether artifact review is enabled;
- whether artifact self-review prevention is enabled;
- whether human oversight is embedded in the runtime or performed as external artifact/log review.

Each run should record the commit hash, model/provider, initial mission, database export, artifact outputs, failure modes, and reproducibility notes. The template in `experiment-log-template.md` gives a starting format.

## 9. Preliminary Observations

The prototype supports a few cautious observations:

- SQLite is sufficient for a minimal shared blackboard with durable message, proposal, and vote records.
- Database triggers can encode simple governance state transitions without a central manager agent.
- A `UNIQUE(proposal_id, reviewer)` constraint reliably prevents duplicate proposal votes.
- The `prevent_self_vote` trigger rejects proposal votes by the proposing agent.
- The `prevent_artifact_self_review` trigger rejects reviews by the current artifact author.
- The sample mission shows that a critic-style agent can produce substantive objections and alternatives, including proposal rejection with replacement structure.
- The sample mission also shows risks of over-discussion and repeated proposal churn. The archived SQLite dump has no persisted self-vote, self-review, or duplicate-vote rows.

These observations are preliminary. They do not show that the architecture improves output quality, reduces hallucination, or outperforms manager-worker systems. The sample mission is not a controlled experiment, and the generated artifact contains claims that need independent source checks before it can be used as research evidence.

## 10. Failure Modes

Observed or plausible failure modes include:

- **Proposal churn:** agents may continue creating overlapping proposals instead of converging.
- **Invalid self-vote behavior:** agents may still try proposal self-votes, but the current schema rejects those inserts. Counting rejected attempts requires audit logging or external process logs.
- **Invalid artifact self-review behavior:** agents may still try to review their own artifact, but the current schema records artifact authorship and rejects those review rows. Counting rejected attempts requires audit logging or external process logs.
- **Role duplication:** several agents may select the same role, leaving other needed roles uncovered.
- **Prompt-level rule drift:** instructions such as "REJECT must include an alternative" are not fully enforced by schema constraints.
- **Stale or unverifiable factual claims:** agents can cite data without verifiable provenance.
- **Runaway token cost:** shorter loop intervals or prolonged debate increase API usage.
- **Schema drift in samples:** old databases may lack newer mission-review tables.
- **Weak artifact grounding:** artifact content is written as complete file text, but source verification is outside the current loop.
- **No central deadlock breaker:** a fully decentralized protocol can stall without a timeout, quorum rule, or human intervention.
- **Limited security model:** LLM-produced action JSON can write artifact files by basename; sandboxing and policy checks are not implemented beyond that.

## 11. Limitations

This prototype has several limitations.

First, the current implementation is a local research prototype, not production infrastructure. It relies on shell scripts, a local SQLite file, `tmux`, and a local or CLI-accessible LLM backend such as Claude Code CLI, Codex CLI, Ollama, or an OpenAI-compatible endpoint. It has no distributed deployment layer, authentication model, tenant isolation, or observability stack.

Second, the governance protocol is minimal. It demonstrates proposal review, proposal self-vote prevention, artifact review, and artifact self-review prevention. It does not yet implement quorum based on active agents, abstentions, reviewer eligibility beyond proposal and artifact authorship, timeouts, proposal closure, or role occupancy constraints.

Third, much of the agent behavior still comes from prompts. The database enforces duplicate vote prevention and approval thresholds, but several norms are only described in `agents/CLAUDE.md`. A model may ignore them or apply them inconsistently.

Fourth, the system has not yet been evaluated under repeated controlled experiments. No statistically meaningful comparison has been run against a single-agent baseline, a manager-worker baseline, or established orchestration approaches such as AutoGen or LangGraph.

That missing comparison should be read in context. AutoGen, CrewAI, LangGraph, and similar systems are relevant comparison points, but they are not direct substitutes for this question. This prototype is closer to an executable social-system experiment than to an optimization layer for specialist task assignment. Claims about productivity, token-cost savings, or superiority over orchestration frameworks are outside the current evidence.

Fifth, output quality is not automatically evaluated. The system can record that an artifact was accepted, but acceptance comes from agent votes rather than an external rubric, independent human judgment, or an objective task score.

Sixth, reproducibility is partial. Source code and tests are versionable, but runtime database logs are ignored by default. Zenodo-ready releases should include selected sample logs, commit hashes, model/provider versions, prompts, and artifact snapshots.

Seventh, the prototype treats organizational activity as mission-driven artifact production and review. That makes experiments easier to reproduce, but it does not answer whether a decentralized organization should be defined by artifacts, ongoing purpose, member development, shared values, adaptation, or other non-artifact functions.

Eighth, Human-in-the-Loop evaluation is not implemented as a core result. The current code can generate artifacts and logs for human inspection, but it does not define an embedded approval interface, reviewer workflow, or LLM-assisted external review protocol. That is intentional for this report. Keeping human review outside the runtime may make the method easier to adapt across domains, but that design choice still needs evaluation.

Finally, the project should not be framed as evidence that decentralized governance is generally superior to centralized orchestration. The contribution is an inspectable design and implementation that makes that question testable.

## 12. Future Work

Near-term work should focus on reproducibility and evaluation:

- add curated sample runs under version control;
- export structured metrics from SQLite;
- record token usage and wall-clock timing;
- implement experiment IDs and run manifests;
- run repeated baseline comparisons;
- add a human rating rubric for final artifacts;
- define external human review templates for generated artifacts and exported logs.

Protocol-level work should include:

- more detailed reviewer eligibility rules for quorum and conflict-of-interest handling;
- quorum rules based on active agents;
- proposal withdrawal and closure;
- role occupancy or role negotiation;
- deadlock detection;
- more detailed artifact-review versioning;
- policy gates for irreversible or risky actions;
- optional embedded human approval checkpoints for high-risk decisions, kept separate from the core decentralized protocol.

Research-facing work should include:

- a formal related-work review expanded from `paper/related-work-notes.md`;
- a separate inquiry into decentralized organizational purpose beyond artifact production;
- a methodological note on using LLM-agent prototypes as cases for organization-theory research;
- comparison of embedded Human-in-the-Loop control with external human review, including LLM-assisted review of generated artifacts and logs;
- domain-specific study designs for education research, such as teacher-to-learner ratio and learning-outcome comparisons, where appropriate validation data are available;
- cautious exploration of non-core domains such as political voting behavior, with explicit attention to validation, bias, and ethics;
- controlled comparison with manager-worker orchestration;
- analysis of when dissent helps or harms;
- study of how much governance can be enforced in schema versus prompts;
- workshop-paper framing if controlled results become strong enough.

## 13. Conclusion

This technical report describes a small decentralized multi-agent prototype in which LLM agents coordinate through a SQLite blackboard and peer-review protocol. The system shows that proposal voting, duplicate vote prevention, decision triggers, artifact writing, and artifact review can be encoded with simple local infrastructure. It also shows the weak spots: prompt-level governance is fragile, debate can churn, output quality is not independently measured, and the evidence is still preliminary.

## References

- Du, Y., Li, S., Torralba, A., Tenenbaum, J. B., & Mordatch, I. (2024). Improving Factuality and Reasoning in Language Models through Multiagent Debate. *Proceedings of the 41st International Conference on Machine Learning*, PMLR 235:11733-11763. https://proceedings.mlr.press/v235/du24e.html
- Erman, L. D., Hayes-Roth, F., Lesser, V. R., & Reddy, D. R. (1980). The Hearsay-II Speech-Understanding System: Integrating Knowledge to Resolve Uncertainty. *ACM Computing Surveys*, 12(2), 213-253. https://doi.org/10.1145/356810.356816
- Hayes-Roth, B. (1985). A Blackboard Architecture for Control. *Artificial Intelligence*, 26(3), 251-321. https://doi.org/10.1016/0004-3702(85)90063-3
- Nii, H. P. (1986). Blackboard Systems, Part One: The Blackboard Model of Problem Solving and the Evolution of Blackboard Architectures. *AI Magazine*, 7(2), 38-53. https://dblp.org/rec/journals/aim/Nii86
- Wu, Q., Bansal, G., Zhang, J., et al. (2023). AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation Framework. arXiv:2308.08155. https://doi.org/10.48550/arXiv.2308.08155
- LangChain. (n.d.). LangGraph overview. Retrieved 2026-05-05, from https://docs.langchain.com/oss/python/langgraph/overview
- LangChain. (n.d.). Multi-agent systems. Retrieved 2026-05-05, from https://docs.langchain.com/oss/python/langchain/multi-agent/index
