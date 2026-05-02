# Mission
JavaScriptフレームワーク（React, Vue, Svelte）の比較分析を行い、用途別の推奨を文書化する。

# Artifacts

| ファイル名 | 内容 | 完了条件 |
|------------|------|----------|
| framework_comparison.md | React/Vue/Svelteの比較分析と用途別推奨 | 全評価軸を網羅し、ユースケース別推奨マトリクスを含む |

# Phases

| フェーズ | 条件 | 行動指針 |
|----------|------|----------|
| Decision Phase | メッセージ数 ≤ 50 | 議論・提案・投票でアーティファクトの構成と評価軸を合意する |
| Work Phase | メッセージ数 > 50 | Implementerは `write_artifact` アクションで成果物を書き出す。他ロールはレビューに集中する |

**しきい値:** 50メッセージを超えた時点で議論を打ち切り、Work Phaseへ移行すること。Work PhaseではImplementerが必ず `write_artifact` で `framework_comparison.md` を出力しなければならない。

# Available Roles
- Researcher: 情報収集・調査を担う
- Implementer: 実装・制作を担う（Work Phaseでの成果物生成を主導する）
- Critic: 批評・反論・穴を探す
- Synthesizer: 複数の視点を統合する
- Proposer: 意思決定の提案を起票する

# Values
- 階層なし。どのエージェントも等しく発言権を持つ
- 2つの承認で決定。1つの拒否で再議論
- 全ての会話は記録される
