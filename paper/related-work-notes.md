# Related Work Notes

These notes separate required reading for the current technical report from candidate related work for future expansion. Only works that have been read and directly connected to the prototype should be promoted into formal references.

## Required Reading for Current Report

### Blackboard Systems

- Nii, H. P. (1986). "Blackboard Systems, Part One: The Blackboard Model of Problem Solving and the Evolution of Blackboard Architectures."
  - Why required: foundational blackboard architecture reference.
  - Use in report: defines the architectural lineage of the shared-state coordination model.

- Erman, L. D., Hayes-Roth, F., Lesser, V. R., & Reddy, D. R. (1980). "The Hearsay-II Speech-Understanding System: Integrating Knowledge to Resolve Uncertainty."
  - Why required: classic blackboard-style system coordinating multiple knowledge sources.
  - Use in report: historical comparison point for multi-source coordination through a shared blackboard.

- Hayes-Roth, B. (1985). "A Blackboard Architecture for Control."
  - Why required: directly relevant to control in blackboard systems.
  - Use in report: contrast central control with database-backed governance triggers.

### LLM Multi-Agent Debate and Orchestration

- Du, Y., Li, S., Torralba, A., Tenenbaum, J. B., & Mordatch, I. (2024). "Improving Factuality and Reasoning in Language Models through Multiagent Debate."
  - Why required: closest research comparison for disagreement and deliberation among LLM agents.
  - Use in report: distinguish conversational debate from persistent proposal/review records.

- AutoGen. "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation Framework."
  - Why required: representative multi-agent conversation framework.
  - Use in report: compare programmable multi-agent orchestration with decentralized blackboard coordination.

- LangGraph / LangChain multi-agent documentation.
  - Why required: representative graph-based, stateful orchestration approach.
  - Use in report: compare graph/workflow control with SQLite-backed shared-state coordination.

## Candidate Related Work

These should not be promoted into formal references until read and explicitly connected to the report.

- CAMEL
  - Possible relevance: role-playing communicative agents.
  - Keep as candidate because the current prototype is not primarily a role-playing framework.

- ChatDev
  - Possible relevance: specialized multi-agent workflow for software development.
  - Keep as candidate because the current prototype is task-general and governance-focused.

- ReConcile
  - Possible relevance: consensus and voting-like mechanisms among diverse LLMs.
  - Keep as candidate because its voting mechanism must be compared carefully with the prototype's proposal/review protocol.

- Wooldridge, M. "An Introduction to MultiAgent Systems."
  - Possible relevance: general MAS background.
  - Keep as candidate for a fuller paper, not necessary for the current technical report.

- CrewAI documentation.
  - Possible relevance: production-oriented multi-agent orchestration framework.
  - Keep as candidate if the report expands its framework comparison section.

## Removed for Now

- Distributed Artificial Intelligence literature
- Stigmergy / Grasse / swarm intelligence
- Collective intelligence literature
- Generic peer review and voting systems
- DAO governance literature
- Human-AI collaboration literature

Reason for removal: these areas are conceptually adjacent but not necessary for the current prototype report. Including them now would broaden the framing without strengthening the core claim.
