# デイリーログ自動生成ワークフロー

スクリーンショットから Activity Log を自動生成するハイブリッド方式。

## アーキテクチャ

```
Phase 0: ファイルサイズフィルタ（500KB未満 → 黒画面）
    ↓
Phase 1: ローカルLLM（moondream）で分類
    ↓
Phase 2: Claude Code で詳細分析 → Obsidian に書き込み
```

## ファイル構成

| ファイル | 役割 |
|----------|------|
| `~/Scripts/generate-daily-log-hybrid.sh` | Phase 0+1 実行 |
| `~/.claude/commands/create-daily-log.md` | Phase 1+2 統合コマンド |
| `~/.claude/commands/create-daily-log-phase2.md` | Phase 2 単体 |

## 実行方法

### 推奨: 1 コマンドで実行

```bash
claude -p '/create-daily-log --backfill'   # バックフィル
claude -p '/create-daily-log'              # 今日
claude -p '/create-daily-log 2025-12-25'   # 指定日
```

### 分離実行（デバッグ時など）

```bash
# Phase 1: ローカルで分類
~/Scripts/generate-daily-log-hybrid.sh --backfill

# Phase 2: Claude Code で詳細分析
claude -p '/create-daily-log-phase2'
```

## 設定値

- スクリーンショット: `~/Screenshots/daily/YYYY-MM-DD/HH-MM.jpg`
- Obsidian Vault: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main`
- 黒画面閾値: 500KB（これ未満は黒画面と判定）
- サンプリング間隔: 10分

## トラブルシューティング

### 黒画面が誤検出される

ファイルサイズ閾値を調整:
```bash
# generate-daily-log-hybrid.sh 内
BLACK_SCREEN_THRESHOLD=512000  # 500KB
```

実際の傾向:
- 黒画面: 約 162KB
- アクティブ画面: 1000KB 以上
