# Session Summary Generator

Claude Code セッションの要約を生成し、Obsidian のデイリーノートに記録します。

## 処理内容

1. `~/.claude/session-logs/pending/` から対象セッションを読み込み
2. 前日 21:01 〜 当日 21:00 の範囲のセッションを抽出
3. Ollama でセッション要約を生成
4. Obsidian のデイリーノートの `## Session Talk` セクションに追記
5. 重要な技術的内容があればナレッジノートを作成
6. 処理済みセッションは `processed/` に移動

## 実行

以下のコマンドを実行してセッション要約を生成してください：

```bash
node ~/.claude/hooks/daily-summary.mjs
```

テストモード（設定確認のみ）：

```bash
node ~/.claude/hooks/daily-summary.mjs --test
```

## 備考

- SessionEnd フックにより、セッション終了時に自動で `pending/` にログが保存されます
- このコマンドは 21:00 以降に実行するか、cron で自動実行することを想定しています
- Ollama と Obsidian REST API が稼働している必要があります

$ARGUMENTS
