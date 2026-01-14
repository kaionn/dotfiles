# Create Daily Log - Phase 2

ハイブリッド方式の Phase 2: ローカル LLM で分類済みの画像を詳細分析し、Activity Log を生成します。

## 前提条件

Phase 1（`~/Scripts/generate-daily-log-hybrid.sh`）が実行済みで、`/tmp/daily-log-hybrid/output/` に分類結果が出力されていること。

## 実行手順

### 1. Phase 1 の結果を確認

```bash
cat /tmp/daily-log-hybrid/output/summary.txt
```

出力がない場合は、先に Phase 1 を実行してください:
```bash
~/Scripts/generate-daily-log-hybrid.sh --backfill
```

### 2. 各日付を処理

`/tmp/daily-log-hybrid/output/` 内の各日付フォルダを処理します。

各日付フォルダには以下のファイルがあります:
- `black_screens.txt`: 黒画面と判定された時刻（そのまま使用）
- `needs_analysis.txt`: 詳細分析が必要な画像パス

### 3. 詳細分析

`needs_analysis.txt` の各行は `時刻|画像パス` 形式です。

各画像を読み込んで以下を分析してください:
- 使用しているアプリケーション（メニューバーを確認）
- 作業内容（コード編集、ドキュメント作成、ブラウジング、会議など）
- 可能であれば具体的なプロジェクト名やファイル名

### 4. Activity Log 生成

黒画面の結果と詳細分析の結果を統合して、以下のフォーマットで Activity Log を生成:

```markdown
### 🌅 午前 (9:00-12:00)
- HH:MM: [作業内容]

### 🌞 午後 (13:00-18:00)
- HH:MM: [作業内容]

### 🌙 夜 (19:00-)
- HH:MM: [作業内容]
```

### 5. デイリーノートに書き込み

Obsidian MCP を使用して書き込んでください:

- Vault パス: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main`
- ノートパス: `00_inbox/daily/YYYY/MM/YYYY-MM-DD.md`
- 存在しない場合: `999_templates/daily/daily_template.md` を元に新規作成
- `## Activity Log` セクションの内容を置き換える形で書き込み

### 6. クリーンアップ

処理完了後:

```bash
rm -rf /tmp/daily-log-hybrid
```

$ARGUMENTS
