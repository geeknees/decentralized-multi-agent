# Decentralized Multi-Agent System

[English](#english) | [日本語](#日本語)

## English

A decentralized autonomous system where multiple AI agents share a SQLite blackboard and make decisions through peer review. Agents run as tmux panes and call a configurable LLM provider to return actions in JSON format.

This repository is also prepared as a research prototype for a Zenodo DOI release. It is a technical-report / working-paper artifact, not a peer-reviewed paper. The implementation is the live development space; the `paper/` directory contains the fixed research framing, evaluation plan, and release notes.

## Research Motivation

Most practical LLM-agent systems use a central manager, graph, router, or workflow engine to decide which agent acts next. This project explores a different question: can peer LLM agents coordinate through a shared blackboard and lightweight governance rules without a standing central orchestrator?

The goal is not to claim that decentralized coordination is generally superior. The goal is to make the design concrete enough to inspect, run, log, and compare against simpler baselines.

This project is not primarily a productivity benchmark against AutoGen, CrewAI, LangGraph, or similar orchestration frameworks. Those systems are important, but they usually focus on arranging specialized agents and work handoffs so that software tasks can be completed more efficiently, often with productivity, reliability, and token-cost tradeoffs in view. This project instead treats decentralized multi-agent coordination as a small social-system experiment. The research question is whether autonomous peer coordination can make progress toward an initially underspecified goal when no single actor has complete expertise, authority, or resources. Productivity or cost reduction may appear in specific domains, but it is not the main objective of this prototype.

As a research prototype, this project also helps organize practical challenges in realizing decentralized organizations with LLM agents. The current implementation addresses two narrow pieces: making a decision phase explicit, and making expected artifacts and their acceptance criteria explicit. A larger organizational question remains open: an organization may not exist only to produce artifacts. Clarifying organizational purpose beyond deliverable production is future research, not a claim made by this implementation.

The project can also be read as an early case of using LLM agents to make organization-theory questions executable and observable. In this repository, that case is limited to decentralized decision making and artifact review. Related future applications could include education research, such as comparing learning outcomes under different teacher-to-learner ratios with LLM-supported simulation or analysis, and political science research, such as exploratory models of voting behavior. Those applications are outside the current implementation and would require domain-specific experimental designs, validation data, and ethical review.

## What this project explores

- Shared-state coordination through SQLite as a blackboard.
- Peer proposal and voting instead of manager-only decisions.
- Artifact review as a separate phase from ordinary discussion.
- Explicit decision phases and artifact definitions as minimal organizational scaffolding.
- LLM-agent prototypes as a way to operationalize selected organization-theory questions.
- Minimal governance rules that can be enforced by database constraints and triggers.
- Failure modes such as proposal churn, role duplication, invalid self-vote attempts, and stalled convergence.

For the detailed working-paper draft, see [`paper/technical-report.md`](paper/technical-report.md).

## Architecture

At a high level, each agent runs the same loop: read the mission and blackboard state, ask an LLM for JSON actions, write those actions to SQLite, export human-readable logs, and repeat. The architecture is closest to a blackboard system: agents do not directly control one another, and the database stores both working context and governance events.

See [`paper/figures.md`](paper/figures.md) for Mermaid diagrams.

## Decision Protocol

- Proposal decisions: two `APPROVE` votes mark a proposal as `DECIDED`.
- Duplicate proposal votes by the same reviewer are blocked by a SQLite `UNIQUE` constraint.
- Proposal self-votes are rejected by the `prevent_self_vote` SQLite trigger.
- `REJECT` comments are required by agent instructions to include an alternative.
- Artifact review: `write_artifact` moves the mission into review; two artifact approvals complete the mission; one artifact rejection reopens it.

Some norms are still prompt-level rather than schema-level. For example, `REJECT` alternatives are required by agent instructions, not by a database constraint.

## Reproducibility

Run the test suite:

```bash
bash tests/run_tests.sh
```

For research runs, record the commit hash, model/provider, number of agents, mission prompt, final state, proposals, votes, artifact outputs, human interventions, and reproducibility notes. Use [`paper/experiment-log-template.md`](paper/experiment-log-template.md).

Generated runtime files such as `db/*.db`, `whole_conversation_doc.md`, and `peer_review_doc.md` are ignored by default. Curated sample runs should be copied into an explicit experiment directory before release.

## Evaluation Plan

The planned comparison set is:

- single-agent baseline;
- central manager-agent baseline;
- decentralized blackboard version;
- human-in-the-loop version or post-run human review condition.

Metrics include task completion rate, time to decision, messages until decision, proposal count, approve/reject ratio, artifact acceptance rate, human intervention points, token cost, wall-clock time, reproducibility, and human-rated artifact quality. Human-in-the-loop is not implemented as a core result in this release. A more composable approach may be to keep the agent system focused on producing artifacts and logs, then have humans review those outputs externally, optionally with LLM-assisted review tools. See [`paper/evaluation-plan.md`](paper/evaluation-plan.md).

## Citation

Citation metadata is provided in [`CITATION.cff`](CITATION.cff). Until a DOI is minted, cite the GitHub repository and version tag. After Zenodo publication, the DOI should be added here and to `CITATION.cff`.

## Limitations

- This is a local shell/Ruby/SQLite prototype, not production infrastructure.
- Current evidence is limited to implementation tests and sample runs, not controlled experiments.
- Output quality is not automatically or independently evaluated.
- Several governance rules are prompt-level and may be ignored by a model.
- Deadlock handling, role occupancy, richer quorum rules, and richer reviewer eligibility rules are future work.
- Human-in-the-loop design is treated as future evaluation work, not as a claimed contribution of the current prototype.

## Roadmap

- Add curated sample runs using the current schema.
- Export structured experiment metrics from SQLite.
- Add token and wall-clock accounting.
- Compare against single-agent and central manager-agent baselines.
- Add richer reviewer eligibility rules for quorum and conflict-of-interest handling.
- Prepare a v0.1.0 GitHub release linked to Zenodo.

## Runtime Architecture

```
┌─────────────────────────────────────────────────────┐
│  tmux session "autonomous"                          │
│                                                     │
│  [agent-alpha] [agent-beta] [agent-gamma] ...       │
│       │              │             │                │
│       └──────────────┴─────────────┘                │
│                      │                              │
│              db/collective.db (SQLite)              │
│                      │                              │
│       ┌──────────────┴─────────────┐                │
│  whole_conversation_doc.md   peer_review_doc.md     │
└─────────────────────────────────────────────────────┘
```

Each agent runs an independent loop:

1. Read unread messages and undecided proposals from the SQLite blackboard.
2. Exit if `mission_state.status = completed`.
3. Pass the mission from `purpose_doc.md` and the current state to `scripts/llm_call.sh`.
4. Parse the JSON action returned by the configured LLM provider and write it to the database.
5. Export Markdown documents and sleep (10 seconds by default).

## Decision Rules

- **2 APPROVE -> DECIDED**: A SQLite trigger updates the status automatically.
- **REJECT**: Return to discussion. Every rejection comment must include an alternative.
- **Duplicate votes by the same agent**: Rejected by a UNIQUE constraint.
- **Proposal self-votes**: Rejected by the `prevent_self_vote` trigger.
- **Artifact self-reviews**: Rejected by the `prevent_artifact_self_review` trigger.
- **Artifact review**: After `write_artifact`, `mission_state.status = review`. Two `APPROVE` votes on `review_artifact` mark the mission as `completed`, while one `REJECT` returns it to `running`.

## File Layout

| File | Role |
|---|---|
| `purpose_doc.md` | Mission, artifacts, phases, and role definitions (edited by a human before launch) |
| `agents/CLAUDE.md` | Instructions for each agent (role selection, phase detection, action format) |
| `agents/agent.sh` | Main agent loop |
| `scripts/init_db.sh` | Initialize the SQLite schema (tables and triggers) |
| `scripts/db_write.sh` | Database write CLI for agents |
| `scripts/llm_call.sh` | Provider adapter for Claude, Codex, Ollama, custom commands, and OpenAI-compatible APIs |
| `scripts/export_docs.sh` | Export SQLite data to Markdown |
| `scripts/extract_json.rb` | Extract JSON from LLM responses |
| `scripts/run_actions.rb` | Execute action JSON |
| `scripts/launch.sh` | Launch multiple agents in a tmux session |
| `scripts/reset_purpose.sh` | Archive the conversation state and replace the mission |
| `whole_conversation_doc.md` | Chronological full conversation log (generated automatically) |
| `peer_review_doc.md` | Proposal and vote log (generated automatically) |

## Setup

```bash
# Check required tools
sqlite3 --version   # SQLite 3.x
tmux -V             # tmux 3.x
ruby --version      # Ruby (mise recommended)
claude --version    # Claude Code CLI, if using LLM_PROVIDER=claude
codex --version     # Codex CLI, if using LLM_PROVIDER=codex
ollama --version    # Ollama, if using LLM_PROVIDER=ollama

# Install on macOS
brew install sqlite tmux
mise install ruby
```

## Usage

### 1. Define the mission

Edit `purpose_doc.md` to define the mission, artifacts, phases, and roles:

```markdown
# Mission
(Write the question or goal this system should solve)

# Artifacts

| File name | Content | Completion criteria |
|-----------|---------|---------------------|
| output.md | Description of the artifact | What counts as done |

# Phases

| Phase | Condition | Guidance |
|-------|-----------|----------|
| Decision Phase | Message count <= 50 | Reach agreement through discussion, proposals, and voting |
| Work Phase | Message count > 50 and mission_state.status = running | The Implementer produces deliverables with write_artifact |
| Review Phase | mission_state.status = review | Review deliverables with review_artifact |
| Completed | mission_state.status = completed | End the agent loop |

# Available Roles
- Researcher: gathers information and investigates
- Implementer: handles implementation and artifact creation (leads output generation in Work Phase)
- Critic: challenges ideas and looks for weaknesses
...
```

List the files to generate and their completion criteria in the **Artifacts** table. Use the **Phases** table to switch behavior based on message count and mission status. On every loop, agents receive `Total messages: N` and decide which phase they are in.

### 2. Launch the agents

```bash
scripts/launch.sh agent-alpha agent-beta agent-gamma
```

### 3. Observe the system

```bash
# Attach to the tmux session
tmux attach -t autonomous

# Check the conversation log
cat whole_conversation_doc.md

# Check peer review status
cat peer_review_doc.md

# Query SQLite directly
sqlite3 db/collective.db "SELECT name, role FROM agents;"
sqlite3 db/collective.db "SELECT sender, content FROM messages ORDER BY id;"
sqlite3 db/collective.db "SELECT title, status FROM proposals;"
```

### 4. Stop the system

```bash
tmux kill-session -t autonomous
```

### 5. Reset the mission and reuse the system

Archive the current database and artifacts, then start over with a new mission:

```bash
# Archive the current state and clear conversation history, votes, and proposals
scripts/reset_purpose.sh

# You can also replace purpose_doc.md with a new file
scripts/reset_purpose.sh new_mission.md
```

Archives are stored under `archive/<timestamp>/`. After that, edit `purpose_doc.md` and restart with `scripts/launch.sh`.

## DB Schema

```sql
agents     (id, name, role, status, last_seen, last_read_id)
messages   (id, sender, recipient, content, created_at)
proposals  (id, proposer, title, content, status, created_at)
reviews    (id, proposal_id, reviewer, vote, comment, created_at)
mission_state    (id, status, artifact_filename, artifact_author, artifact_written_at, completed_at, updated_at)
artifact_reviews (id, filename, reviewer, vote, comment, created_at)
```

The `prevent_self_vote` trigger rejects review rows where the proposal proposer and reviewer are the same agent.
The `prevent_artifact_self_review` trigger rejects artifact review rows where the artifact author and reviewer are the same agent.
The `auto_decide` trigger updates `proposals.status` to `DECIDED` when two or more `APPROVE` votes exist after an INSERT into `reviews`.
The `auto_complete_mission` trigger updates `mission_state.status` to `completed` when two or more `APPROVE` votes exist for the same artifact after an INSERT into `artifact_reviews`.
The `auto_reopen_mission` trigger returns `mission_state.status` to `running` when an artifact review is `REJECT`.

## Agent Action Format

Each agent returns JSON like this:

```json
{
  "actions": [
    {"type": "set_role", "role": "Researcher"},
    {"type": "post_message", "recipient": "ALL", "content": "Message"},
    {"type": "create_proposal", "title": "Title", "content": "Details"},
    {"type": "vote", "proposal_id": 1, "vote": "APPROVE", "comment": "Reason"},
    {"type": "vote", "proposal_id": 2, "vote": "REJECT", "comment": "Reason for rejection and an alternative"},
    {"type": "write_artifact", "filename": "output.md", "content": "# Full file content..."},
    {"type": "review_artifact", "filename": "output.md", "vote": "APPROVE", "comment": "Meets the completion criteria"}
  ]
}
```

`write_artifact` is used in Work Phase when the Implementer outputs a file defined in the Artifacts table of `purpose_doc.md`. The `content` field must contain the full file content, not a diff.
`review_artifact` is used for artifact review. When two `APPROVE` votes are collected, the mission is completed and each agent loop exits on its next check.

## Tests

```bash
bash tests/run_tests.sh
# Results: 67 passed, 0 failed
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DB_PATH` | `db/collective.db` | Path to the SQLite file |
| `LOOP_INTERVAL` | `10` | Loop interval in seconds |
| `LOOP_MAX` | `0` (infinite) | For tests: stop after the specified number of loops |
| `EXPORT_DIR` | Project root | Markdown export destination |
| `SQLITE_BUSY_TIMEOUT_MS` | `5000` | SQLite busy timeout in milliseconds for concurrent agent reads/writes |
| `LLM_PROVIDER` | `claude` | Provider used by `scripts/llm_call.sh`: `claude`, `codex`, `ollama`, or `openai-compatible` |
| `LLM_MODEL` | empty | Model name for providers that require one |
| `LLM_ENDPOINT` | empty | Chat completions endpoint for OpenAI-compatible providers |
| `LLM_API_KEY` | empty | Optional bearer token for OpenAI-compatible providers |
| `LLM_TEMPERATURE` | `0.2` | Temperature used by OpenAI-compatible providers |
| `LLM_CMD` | empty | Custom stdin-to-stdout command. When set, it overrides `LLM_PROVIDER` |

### LLM provider examples

```bash
# Default Claude Code CLI backend
LLM_PROVIDER=claude scripts/launch.sh agent-alpha agent-beta agent-gamma

# Codex CLI backend. The adapter runs codex exec with read-only sandboxing.
LLM_PROVIDER=codex LLM_MODEL=gpt-5.2 scripts/launch.sh agent-alpha agent-beta agent-gamma

# Ollama CLI backend
LLM_PROVIDER=ollama LLM_MODEL=qwen2.5-coder:14b scripts/launch.sh agent-alpha agent-beta agent-gamma

# OpenAI-compatible local endpoint, such as Ollama or LM Studio
LLM_PROVIDER=openai-compatible \
LLM_ENDPOINT=http://localhost:11434/v1/chat/completions \
LLM_MODEL=qwen2.5-coder:14b \
scripts/launch.sh agent-alpha agent-beta agent-gamma

# Any custom command that reads stdin and writes a model response to stdout
LLM_CMD='my-llm-command --json' scripts/launch.sh agent-alpha agent-beta agent-gamma
```

## 日本語

N個のAIエージェントがSQLiteブラックボードを共有し、ピアレビューで意思決定する自律分散システム。エージェントはtmuxペインとして動作し、設定されたLLM providerを呼び出してJSON形式のアクションを返す。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│  tmux session "autonomous"                          │
│                                                     │
│  [agent-alpha] [agent-beta] [agent-gamma] ...       │
│       │              │             │                │
│       └──────────────┴─────────────┘                │
│                      │                              │
│              db/collective.db (SQLite)              │
│                      │                              │
│       ┌──────────────┴─────────────┐                │
│  whole_conversation_doc.md   peer_review_doc.md     │
└─────────────────────────────────────────────────────┘
```

各エージェントは独立したループを実行する：

1. SQLiteブラックボードから未読メッセージ・未決プロポーザルを読む
2. `mission_state.status = completed` なら終了する
3. `purpose_doc.md` のミッションと現在の状態を `scripts/llm_call.sh` に渡す
4. 設定されたLLM providerが返したJSONアクションを解析し、DBに書き込む
5. Markdownドキュメントをエクスポートして睡眠（デフォルト10秒）

## 意思決定ルール

- **2 APPROVE → DECIDED**: SQLiteトリガーが自動的にステータスを更新
- **REJECT**: 再議論。コメントには必ず代替案を含める
- **同一エージェントの二重投票**: UNIQUE制約で拒否
- **proposalの自己投票**: `prevent_self_vote` トリガーで拒否
- **成果物の自己レビュー**: `prevent_artifact_self_review` トリガーで拒否
- **成果物レビュー**: `write_artifact` 後に `mission_state.status = review` となり、`review_artifact` の2 APPROVEで `completed`、1 REJECTで `running` に戻る

## ファイル構成

| ファイル | 役割 |
|---|---|
| `purpose_doc.md` | ミッション・アーティファクト・フェーズ・ロール定義（起動前に人間が編集） |
| `agents/CLAUDE.md` | 各エージェントへの指示（ロール選択・フェーズ検知・アクション形式） |
| `agents/agent.sh` | メインエージェントループ |
| `scripts/init_db.sh` | SQLiteスキーマ初期化（テーブル＋トリガー） |
| `scripts/db_write.sh` | エージェント用DB書き込みCLI |
| `scripts/llm_call.sh` | Claude、Codex、Ollama、custom command、OpenAI互換API用provider adapter |
| `scripts/export_docs.sh` | SQLite → Markdown エクスポート |
| `scripts/extract_json.rb` | LLM応答からJSONを抽出 |
| `scripts/run_actions.rb` | アクションJSONを実行 |
| `scripts/launch.sh` | tmuxセッションで複数エージェント起動 |
| `scripts/reset_purpose.sh` | 会話状態をアーカイブしてミッションを差し替える |
| `whole_conversation_doc.md` | 全会話の時系列ログ（自動生成） |
| `peer_review_doc.md` | プロポーザルと投票のログ（自動生成） |

## セットアップ

```bash
# 依存ツールの確認
sqlite3 --version   # SQLite 3.x
tmux -V             # tmux 3.x
ruby --version      # Ruby (mise推奨)
claude --version    # LLM_PROVIDER=claude の場合
codex --version     # LLM_PROVIDER=codex の場合
ollama --version    # LLM_PROVIDER=ollama の場合

# macOSでのインストール
brew install sqlite tmux
mise install ruby
```

## 使い方

### 1. ミッションを設定する

`purpose_doc.md` を編集してミッション・成果物・フェーズ・ロールを定義する：

```markdown
# Mission
（このシステムで解決したい問いや目標を書く）

# Artifacts

| ファイル名 | 内容 | 完了条件 |
|------------|------|----------|
| output.md | 成果物の説明 | 完了とみなす条件 |

# Phases

| フェーズ | 条件 | 行動指針 |
|----------|------|----------|
| Decision Phase | メッセージ数 ≤ 50 | 議論・提案・投票で構成を合意する |
| Work Phase | メッセージ数 > 50 かつ mission_state.status = running | Implementerが write_artifact で成果物を出力する |
| Review Phase | mission_state.status = review | 成果物を review_artifact でレビューする |
| Completed | mission_state.status = completed | エージェントループを終了する |

# Available Roles
- Researcher: 情報収集・調査を担う
- Implementer: 実装・制作を担う（Work Phaseでの成果物生成を主導する）
- Critic: 批評・反論・穴を探す
...
```

**Artifacts** テーブルには生成すべきファイルと完了条件を列挙する。**Phases** テーブルでメッセージ数に応じた行動モードを切り替える。エージェントは毎ループ `Total messages: N` を受け取り、自分がどのフェーズにいるかを判断する。

### 2. エージェントを起動する

```bash
scripts/launch.sh agent-alpha agent-beta agent-gamma
```

### 3. 観察する

```bash
# tmuxセッションにアタッチ
tmux attach -t autonomous

# 会話ログを確認
cat whole_conversation_doc.md

# ピアレビューの状況を確認
cat peer_review_doc.md

# SQLiteを直接クエリ
sqlite3 db/collective.db "SELECT name, role FROM agents;"
sqlite3 db/collective.db "SELECT sender, content FROM messages ORDER BY id;"
sqlite3 db/collective.db "SELECT title, status FROM proposals;"
```

### 4. 停止する

```bash
tmux kill-session -t autonomous
```

### 5. ミッションをリセットして再利用する

現在のDBと成果物をアーカイブし、新しいミッションでやり直す：

```bash
# 現在の状態をアーカイブし、会話履歴・投票・提案をクリア
scripts/reset_purpose.sh

# 新しい purpose_doc.md を指定して置き換えることも可能
scripts/reset_purpose.sh new_mission.md
```

アーカイブは `archive/<タイムスタンプ>/` に保存される。その後 `purpose_doc.md` を編集し、`scripts/launch.sh` で再起動する。

## DBスキーマ

```sql
agents     (id, name, role, status, last_seen, last_read_id)
messages   (id, sender, recipient, content, created_at)
proposals  (id, proposer, title, content, status, created_at)
reviews    (id, proposal_id, reviewer, vote, comment, created_at)
mission_state    (id, status, artifact_filename, artifact_author, artifact_written_at, completed_at, updated_at)
artifact_reviews (id, filename, reviewer, vote, comment, created_at)
```

`prevent_self_vote` トリガーが、proposalの提案者とreviewerが同一エージェントであるreview行を拒否する。
`prevent_artifact_self_review` トリガーが、成果物の作成者とreviewerが同一エージェントであるartifact review行を拒否する。
`auto_decide` トリガーが `reviews` への INSERT後に APPROVE が2件以上あれば `proposals.status` を `DECIDED` に更新する。
`auto_complete_mission` トリガーが `artifact_reviews` への INSERT後に同じ成果物の APPROVE が2件以上あれば `mission_state.status` を `completed` に更新する。
`auto_reopen_mission` トリガーが成果物レビューの REJECT で `mission_state.status` を `running` に戻す。

## エージェントのアクション形式

各エージェントは以下のJSONを返す：

```json
{
  "actions": [
    {"type": "set_role", "role": "Researcher"},
    {"type": "post_message", "recipient": "ALL", "content": "メッセージ"},
    {"type": "create_proposal", "title": "タイトル", "content": "詳細"},
    {"type": "vote", "proposal_id": 1, "vote": "APPROVE", "comment": "理由"},
    {"type": "vote", "proposal_id": 2, "vote": "REJECT", "comment": "却下理由と代替案"},
    {"type": "write_artifact", "filename": "output.md", "content": "# ファイル内容..."},
    {"type": "review_artifact", "filename": "output.md", "vote": "APPROVE", "comment": "完了条件を満たしている"}
  ]
}
```

`write_artifact` は Work Phase で Implementer が `purpose_doc.md` の Artifacts テーブルに定義されたファイルを出力するために使う。`content` にはファイルの完全な内容（差分ではなく全文）を渡す。
`review_artifact` は成果物レビュー用のアクションで、2つの APPROVE が揃うとミッションが完了し、各エージェントループは次回チェック時に終了する。

## テスト

```bash
bash tests/run_tests.sh
# Results: 67 passed, 0 failed
```

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `DB_PATH` | `db/collective.db` | SQLiteファイルのパス |
| `LOOP_INTERVAL` | `10` | ループ間隔（秒） |
| `LOOP_MAX` | `0`（無限） | テスト用：指定回数でループ終了 |
| `EXPORT_DIR` | プロジェクトルート | Markdownエクスポート先 |
| `SQLITE_BUSY_TIMEOUT_MS` | `5000` | 複数agentの同時読み書き向けSQLite busy timeout（ミリ秒） |
| `LLM_PROVIDER` | `claude` | `scripts/llm_call.sh` が使うprovider: `claude`, `codex`, `ollama`, `openai-compatible` |
| `LLM_MODEL` | 空 | providerが必要とするmodel名 |
| `LLM_ENDPOINT` | 空 | OpenAI互換provider用chat completions endpoint |
| `LLM_API_KEY` | 空 | OpenAI互換provider用の任意bearer token |
| `LLM_TEMPERATURE` | `0.2` | OpenAI互換provider用temperature |
| `LLM_CMD` | 空 | stdinを読みstdoutへ応答を書くcustom command。設定時は`LLM_PROVIDER`より優先 |
