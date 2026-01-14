# Create Daily Log

ハイブリッド方式でスクリーンショットから Activity Log を自動生成します。

## 引数

- `$ARGUMENTS`: 以下のいずれか
  - 日付（YYYY-MM-DD 形式）: 指定日のログを作成
  - `--backfill`: 2025-12-25 から今日までの欠けているログを一括作成
  - 省略: 今日の日付

## 実行手順

### 1. Phase 1: ローカル LLM で分類

まず以下のコマンドを実行して、ローカル LLM（moondream）で黒画面をフィルタリングしてください:

```bash
~/Scripts/generate-daily-log-hybrid.sh $ARGUMENTS
```

出力を確認し、Phase 1 が完了したら次のステップへ進んでください。

### 2. Phase 1 結果を確認

```bash
cat /tmp/daily-log-hybrid/output/summary.txt
```

処理対象の日付がない場合は終了してください。

### 3. Phase 2: 各日付を処理

`/tmp/daily-log-hybrid/output/` 内の各日付フォルダを処理します。

各日付フォルダには以下のファイルがあります:
- `black_screens.txt`: 黒画面と判定された時刻（そのまま使用）
- `needs_analysis.txt`: 詳細分析が必要な画像パス

### 4. 詳細分析

`needs_analysis.txt` の各行は `時刻|画像パス` 形式です。

各画像を読み込んで以下を分析してください:
- 使用しているアプリケーション（メニューバーを確認）
- 作業内容（コード編集、ドキュメント作成、ブラウジング、会議など）
- 可能であれば具体的なプロジェクト名やファイル名

### 5. Activity Log 生成

黒画面の結果と詳細分析の結果を統合して、以下のフォーマットで Activity Log を生成:

```markdown
### 🌅 午前 (9:00-12:00)
- HH:MM: [作業内容]

### 🌞 午後 (13:00-18:00)
- HH:MM: [作業内容]

### 🌙 夜 (19:00-)
- HH:MM: [作業内容]
```

### 6. デイリーノートに書き込み

Obsidian MCP を使用して書き込んでください:

- Vault パス: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main`
- ノートパス: `00_inbox/daily/YYYY/MM/YYYY-MM-DD.md`
- 存在しない場合: `999_templates/daily/daily_template.md` を元に新規作成
- `## Activity Log` セクションの内容を置き換える形で書き込み

### 7. クリーンアップ

処理完了後:

```bash
rm -rf /tmp/daily-log-hybrid
```

$ARGUMENTS
