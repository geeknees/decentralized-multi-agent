# Decentralized Multi-Agent System

[English](#english) | [日本語](#日本語)

## English

A decentralized autonomous system where multiple AI agents share a SQLite blackboard and make decisions through peer review. Agents run as tmux panes and call `claude --print` to return actions in JSON format.

## Architecture

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
3. Pass the mission from `purpose_doc.md` and the current state to `claude --print`.
4. Parse the JSON action returned by Claude and write it to the database.
5. Export Markdown documents and sleep (10 seconds by default).

## Decision Rules

- **2 APPROVE -> DECIDED**: A SQLite trigger updates the status automatically.
- **REJECT**: Return to discussion. Every rejection comment must include an alternative.
- **Duplicate votes by the same agent**: Rejected by a UNIQUE constraint.
- **Artifact review**: After `write_artifact`, `mission_state.status = review`. Two `APPROVE` votes on `review_artifact` mark the mission as `completed`, while one `REJECT` returns it to `running`.

## File Layout

| File | Role |
|---|---|
| `purpose_doc.md` | Mission, artifacts, phases, and role definitions (edited by a human before launch) |
| `agents/CLAUDE.md` | Instructions for each agent (role selection, phase detection, action format) |
| `agents/agent.sh` | Main agent loop |
| `scripts/init_db.sh` | Initialize the SQLite schema (tables and triggers) |
| `scripts/db_write.sh` | Database write CLI for agents |
| `scripts/export_docs.sh` | Export SQLite data to Markdown |
| `scripts/extract_json.rb` | Extract JSON from Claude responses |
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
claude --version    # Claude Code CLI

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
mission_state    (id, status, artifact_filename, artifact_written_at, completed_at, updated_at)
artifact_reviews (id, filename, reviewer, vote, comment, created_at)
```

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
# Results: 44 passed, 0 failed
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DB_PATH` | `db/collective.db` | Path to the SQLite file |
| `LOOP_INTERVAL` | `10` | Loop interval in seconds |
| `LOOP_MAX` | `0` (infinite) | For tests: stop after the specified number of loops |
| `EXPORT_DIR` | Project root | Markdown export destination |

## 日本語

N個のAIエージェントがSQLiteブラックボードを共有し、ピアレビューで意思決定する自律分散システム。エージェントはtmuxペインとして動作し、`claude --print` を呼び出してJSON形式のアクションを返す。

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
3. `purpose_doc.md` のミッションと現在の状態を `claude --print` に渡す
4. Claude が返したJSONアクションを解析し、DBに書き込む
5. Markdownドキュメントをエクスポートして睡眠（デフォルト10秒）

## 意思決定ルール

- **2 APPROVE → DECIDED**: SQLiteトリガーが自動的にステータスを更新
- **REJECT**: 再議論。コメントには必ず代替案を含める
- **同一エージェントの二重投票**: UNIQUE制約で拒否
- **成果物レビュー**: `write_artifact` 後に `mission_state.status = review` となり、`review_artifact` の2 APPROVEで `completed`、1 REJECTで `running` に戻る

## ファイル構成

| ファイル | 役割 |
|---|---|
| `purpose_doc.md` | ミッション・アーティファクト・フェーズ・ロール定義（起動前に人間が編集） |
| `agents/CLAUDE.md` | 各エージェントへの指示（ロール選択・フェーズ検知・アクション形式） |
| `agents/agent.sh` | メインエージェントループ |
| `scripts/init_db.sh` | SQLiteスキーマ初期化（テーブル＋トリガー） |
| `scripts/db_write.sh` | エージェント用DB書き込みCLI |
| `scripts/export_docs.sh` | SQLite → Markdown エクスポート |
| `scripts/extract_json.rb` | Claude応答からJSONを抽出 |
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
claude --version    # Claude Code CLI

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
mission_state    (id, status, artifact_filename, artifact_written_at, completed_at, updated_at)
artifact_reviews (id, filename, reviewer, vote, comment, created_at)
```

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
# Results: 44 passed, 0 failed
```

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `DB_PATH` | `db/collective.db` | SQLiteファイルのパス |
| `LOOP_INTERVAL` | `10` | ループ間隔（秒） |
| `LOOP_MAX` | `0`（無限） | テスト用：指定回数でループ終了 |
| `EXPORT_DIR` | プロジェクトルート | Markdownエクスポート先 |
