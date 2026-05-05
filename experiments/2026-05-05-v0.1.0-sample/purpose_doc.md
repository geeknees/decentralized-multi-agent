# Mission

Produce a concise technical note that explains one design decision in this repository: using SQLite triggers to enforce peer-review governance rules.

# Artifacts

| File name | Content | Completion criteria |
|-----------|---------|---------------------|
| sample_decision_report.md | A short technical note about SQLite-trigger-based governance in this system | Includes problem, implemented mechanism, expected benefit, limitations, and one future improvement |

# Phases

| Phase | Condition | Guidance |
|-------|-----------|----------|
| Decision Phase | Message count <= 6 and mission_state.status = running | Discuss the outline briefly, create at least one proposal, and vote. Agents must not vote on their own proposals. |
| Work Phase | Message count > 6 and mission_state.status = running | The Implementer must write `sample_decision_report.md` using `write_artifact`. |
| Review Phase | mission_state.status = review | Agents other than the artifact author review the artifact with `review_artifact`. |
| Completed | mission_state.status = completed | End the agent loop. |

# Available Roles

- Researcher: identifies implementation facts from the repository context
- Implementer: writes the final artifact during Work Phase
- Critic: checks limitations and overclaims
- Synthesizer: reconciles discussion into a concise structure
- Proposer: creates decision proposals for the group

# Values

- Keep claims modest and tied to the implementation.
- Use proposal and artifact review rather than unilateral decisions.
- Do not approve your own proposal.
- Do not review your own artifact.
- Prefer a small complete artifact over a broad unfinished one.
