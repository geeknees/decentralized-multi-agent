# Figures

The following Mermaid diagrams can be rendered in GitHub or exported for a technical report.

## System Architecture Diagram

```mermaid
flowchart TB
    subgraph T[tmux session: autonomous]
        A1[agent-alpha<br/>agents/agent.sh]
        A2[agent-beta<br/>agents/agent.sh]
        A3[agent-gamma<br/>agents/agent.sh]
    end

    P[purpose_doc.md<br/>mission, roles, phases, artifacts]
    C[agents/CLAUDE.md<br/>agent instructions]
    LLM[claude --print]
    DB[(SQLite blackboard<br/>db/collective.db)]
    D1[whole_conversation_doc.md]
    D2[peer_review_doc.md]

    P --> A1
    P --> A2
    P --> A3
    C --> A1
    C --> A2
    C --> A3
    A1 <--> DB
    A2 <--> DB
    A3 <--> DB
    A1 --> LLM
    A2 --> LLM
    A3 --> LLM
    LLM --> A1
    LLM --> A2
    LLM --> A3
    DB --> D1
    DB --> D2
```

## Agent Loop

```mermaid
flowchart TD
    Start([Start agent process])
    Register[Register or refresh agent row]
    Check{mission_state.status == completed?}
    Read[Read unread messages, open proposals,<br/>mission state, artifact reviews]
    Prompt[Build prompt from purpose_doc.md<br/>and blackboard state]
    Call[Call claude --print]
    Parse[Extract JSON actions]
    Apply[Run actions and write DB/artifact]
    Export[Export Markdown logs]
    Sleep[Sleep LOOP_INTERVAL]
    Exit([Exit loop])

    Start --> Register --> Check
    Check -- yes --> Exit
    Check -- no --> Read --> Prompt --> Call --> Parse --> Apply --> Export --> Sleep --> Check
```

## Proposal / Approve / Reject Flow

```mermaid
stateDiagram-v2
    [*] --> Open: create_proposal
    Open --> Open: REJECT with alternative
    Open --> Open: one APPROVE
    Open --> Decided: second APPROVE<br/>auto_decide trigger
    Open --> Error: duplicate reviewer vote
    Decided --> [*]
```

## Artifact Review Flow

```mermaid
stateDiagram-v2
    [*] --> Running
    Running --> Review: write_artifact
    Review --> Review: one APPROVE
    Review --> Completed: second APPROVE<br/>auto_complete_mission trigger
    Review --> Running: REJECT<br/>auto_reopen_mission trigger
    Completed --> [*]
```

## Database Schema Overview

```mermaid
erDiagram
    agents {
        integer id PK
        text name UK
        text role
        text status
        datetime last_seen
        integer last_read_id
    }

    messages {
        integer id PK
        text sender
        text recipient
        text content
        datetime created_at
    }

    proposals {
        integer id PK
        text proposer
        text title
        text content
        text status
        datetime created_at
    }

    reviews {
        integer id PK
        integer proposal_id FK
        text reviewer
        text vote
        text comment
        datetime created_at
    }

    mission_state {
        integer id PK
        text status
        text artifact_filename
        text artifact_author
        datetime artifact_written_at
        datetime completed_at
        datetime updated_at
    }

    artifact_reviews {
        integer id PK
        text filename
        text reviewer
        text vote
        text comment
        datetime created_at
    }

    proposals ||--o{ reviews : receives
```

## Figure TODOs

- Add a diagram comparing centralized manager-worker orchestration against the blackboard architecture.
- Add an experiment pipeline diagram once structured experiment folders exist.
- Add a release-package diagram showing GitHub source, Zenodo archive, and DOI backlink.
