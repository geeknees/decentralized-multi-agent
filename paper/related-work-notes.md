# Related Work Notes

These notes are a starting point for a future related-work section. Items marked "verified" have at least a stable URL, DOI, official documentation page, or bibliographic index entry checked during preparation. Items marked "to verify" should not be promoted into formal references until citation details are confirmed.

## Blackboard Systems

- **Nii, H. P. (1986). "Blackboard Systems, Part One: The Blackboard Model of Problem Solving and the Evolution of Blackboard Architectures." AI Magazine.**  
  Status: verified via DBLP entry.  
  URL: https://dblp.org/rec/journals/aim/Nii86  
  Relevance: foundational overview of blackboard problem solving and architecture evolution.

- **Erman, L. D., Hayes-Roth, F., Lesser, V. R., & Reddy, D. R. (1980). "The Hearsay-II Speech-Understanding System: Integrating Knowledge to Resolve Uncertainty." ACM Computing Surveys.**  
  Status: verified DOI.  
  DOI: https://doi.org/10.1145/356810.356816  
  Relevance: classic blackboard-style system coordinating multiple knowledge sources under uncertainty.

- **Hayes-Roth, B. (1985). "A Blackboard Architecture for Control." Artificial Intelligence.**  
  Status: verified DOI.  
  DOI: https://doi.org/10.1016/0004-3702(85)90063-3  
  Relevance: discusses control in blackboard systems, directly relevant to the absence or presence of a central controller.

- **Corkill, D. (1991). "Blackboard Systems." AI Expert.**  
  Status: verified via UMass publication page.  
  URL: http://mas.cs.umass.edu/paper/218  
  Relevance: accessible survey of what blackboard systems are and where they fit.

## Multi-Agent Systems

- **Wooldridge, M. "An Introduction to MultiAgent Systems."**  
  Status: to verify edition and citation details before formal use.  
  Relevance: broad conceptual background on agents, coordination, and multi-agent design.

- **Distributed Artificial Intelligence literature.**  
  Status: to verify specific sources.  
  Relevance: useful for contrasting shared blackboard coordination with distributed problem solving and coordination protocols.

## LLM Multi-Agent Debate and Collaboration

- **Du, Y., Li, S., Torralba, A., Tenenbaum, J. B., & Mordatch, I. (2024). "Improving Factuality and Reasoning in Language Models through Multiagent Debate." ICML / PMLR.**  
  Status: verified PMLR page and arXiv DOI.  
  URL: https://proceedings.mlr.press/v235/du24e.html  
  DOI: https://doi.org/10.48550/arXiv.2305.14325  
  Relevance: tests debate among multiple LLM instances; useful comparison for proposal/review mechanisms.

- **Li, G., Hammoud, H. A. K., Itani, H., Khizbullin, D., & Ghanem, B. (2023). "CAMEL: Communicative Agents for 'Mind' Exploration of Large Scale Language Model Society."**  
  Status: verified arXiv DOI.  
  DOI: https://doi.org/10.48550/arXiv.2303.17760  
  Relevance: role-playing communicative agents and autonomous cooperation.

- **Qian, C. et al. (2023). "ChatDev: Communicative Agents for Software Development."**  
  Status: to verify final venue and citation details.  
  Candidate arXiv: https://arxiv.org/abs/2307.07924  
  Relevance: multi-agent software-development workflow using specialized communicative roles.

- **ReConcile: Round-Table Conference Improves Reasoning via Consensus among Diverse LLMs.**  
  Status: to verify before formal citation.  
  Candidate arXiv: https://arxiv.org/abs/2309.13007  
  Relevance: consensus and voting-like mechanisms among diverse LLMs.

## Orchestration Frameworks

- **AutoGen. "AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation Framework."**  
  Status: verified Microsoft Research page and arXiv DOI.  
  Microsoft Research: https://www.microsoft.com/en-us/research/publication/autogen-enabling-next-gen-llm-applications-via-multi-agent-conversation-framework/  
  DOI: https://doi.org/10.48550/arXiv.2308.08155  
  Relevance: widely used multi-agent framework built around conversable agents and programmable interaction patterns.

- **LangGraph / LangChain multi-agent documentation.**  
  Status: verified official documentation.  
  LangGraph overview: https://docs.langchain.com/oss/python/langgraph/overview  
  Multi-agent docs: https://docs.langchain.com/oss/python/langchain/multi-agent/index  
  Relevance: graph-based, stateful orchestration and common patterns such as subagents, handoffs, routers, and custom workflows.

- **CrewAI documentation.**  
  Status: verified official documentation.  
  URL: https://docs.crewai.com/  
  Relevance: practical orchestration framework combining flows and crews, with a clear contrast between structured control and autonomous teams.

## Stigmergy

- **Grassé and termite stigmergy origins.**  
  Status: to verify exact citation and translation details.  
  Relevance: indirect coordination through environmental traces is conceptually related to agents coordinating through a shared blackboard.

- **Stigmergy in multi-agent systems and swarm intelligence.**  
  Status: to verify specific survey sources.  
  Relevance: may help frame SQLite messages and proposals as persistent environmental traces rather than direct commands.

## Collective Intelligence and Peer Review

- **Collective intelligence literature.**  
  Status: to verify specific sources.  
  Relevance: useful for framing multi-agent decision-making, diversity of viewpoints, and aggregation of judgments.

- **Peer review and voting systems.**  
  Status: to verify specific computational or governance references.  
  Relevance: the proposal-review protocol resembles lightweight peer review but should not be equated with scholarly peer review.

## DAO Governance

- **DAO governance literature.**  
  Status: to verify specific sources.  
  Relevance: may provide terminology for proposals, votes, quorum, delegation, and governance failure modes. Use carefully; this prototype is not a blockchain or DAO system.

## Human-AI Collaboration

- **Human-in-the-loop agent frameworks and oversight.**  
  Status: to verify specific sources.  
  Relevance: needed for future comparison with runs where humans intervene at proposal, artifact, or safety gates.

## Notes for Formal References

- Do not include unverified DOI or venue claims in `technical-report.md`.
- For arXiv-only works, label them as arXiv/preprint unless a final venue is verified.
- For framework documentation, include retrieval date because the pages change over time.
- Separate related work from evaluation claims. Related systems show design context, not empirical superiority.
