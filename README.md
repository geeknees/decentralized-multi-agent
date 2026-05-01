# Decentralized Multi-Agent System

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
2. `purpose_doc.md` のミッションと現在の状態を `claude --print` に渡す
3. Claude が返したJSONアクションを解析し、DBに書き込む
4. Markdownドキュメントをエクスポートして睡眠（デフォルト10秒）

## 意思決定ルール

- **2 APPROVE → DECIDED**: SQLiteトリガーが自動的にステータスを更新
- **REJECT**: 再議論。コメントには必ず代替案を含める
- **同一エージェントの二重投票**: UNIQUE制約で拒否

## ファイル構成

| ファイル | 役割 |
|---|---|
| `purpose_doc.md` | ミッションとロール定義（起動前に人間が編集） |
| `agents/CLAUDE.md` | 各エージェントへの指示（ロール選択・アクション形式） |
| `agents/agent.sh` | メインエージェントループ |
| `scripts/init_db.sh` | SQLiteスキーマ初期化（テーブル＋トリガー） |
| `scripts/db_write.sh` | エージェント用DB書き込みCLI |
| `scripts/export_docs.sh` | SQLite → Markdown エクスポート |
| `scripts/extract_json.rb` | Claude応答からJSONを抽出 |
| `scripts/run_actions.rb` | アクションJSONを実行 |
| `scripts/launch.sh` | tmuxセッションで複数エージェント起動 |
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

`purpose_doc.md` を編集してミッションとロールを定義する：

```markdown
# Mission
（このシステムで解決したい問いや目標を書く）

# Available Roles
- Researcher: 情報収集・調査を担う
- Critic: 批評・反論・穴を探す
...
```

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

## DBスキーマ

```sql
agents     (id, name, role, status, last_seen, last_read_id)
messages   (id, sender, recipient, content, created_at)
proposals  (id, proposer, title, content, status, created_at)
reviews    (id, proposal_id, reviewer, vote, comment, created_at)
```

`auto_decide` トリガーが `reviews` への INSERT後に APPROVE が2件以上あれば `proposals.status` を `DECIDED` に更新する。

## エージェントのアクション形式

各エージェントは以下のJSONを返す：

```json
{
  "actions": [
    {"type": "set_role", "role": "Researcher"},
    {"type": "post_message", "recipient": "ALL", "content": "メッセージ"},
    {"type": "create_proposal", "title": "タイトル", "content": "詳細"},
    {"type": "vote", "proposal_id": 1, "vote": "APPROVE", "comment": "理由"},
    {"type": "vote", "proposal_id": 2, "vote": "REJECT", "comment": "却下理由と代替案"}
  ]
}
```

## テスト

```bash
bash tests/run_tests.sh
# Results: 30 passed, 0 failed
```

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `DB_PATH` | `db/collective.db` | SQLiteファイルのパス |
| `LOOP_INTERVAL` | `10` | ループ間隔（秒） |
| `LOOP_MAX` | `0`（無限） | テスト用：指定回数でループ終了 |
| `EXPORT_DIR` | プロジェクトルート | Markdownエクスポート先 |
