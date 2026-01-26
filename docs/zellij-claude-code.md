# Zellij Claude Code レイアウト

Claude Code CLI と lazygit を組み合わせた開発用ダッシュボードレイアウト。

## 概要

```
┌─────────────────────┬─────────────────────┐
│                     │    Claude Code      │
│       Shell         │       CLI           │
│       (50%)         ├─────────────────────┤
│                     │     lazygit         │
└─────────────────────┴─────────────────────┘
```

## 使い方

```bash
# 対象ディレクトリに移動して起動
cd /path/to/project
zellij --layout claude-code
```

## 設定ファイル

| ファイル | 説明 |
|----------|------|
| `~/.config/zellij/config.kdl` | メイン設定（テーマ、キーバインド） |
| `~/.config/zellij/layouts/claude-code.kdl` | レイアウト定義 |

## カスタムテーマ: claude-code

TokyoNight ベースのカラースキーム:

```kdl
themes {
    claude-code {
        fg "#c0caf5"
        bg "#1a1b26"
        black "#000000"
        red "#f7768e"
        green "#9ece6a"
        yellow "#e0af68"
        blue "#7aa2f7"
        magenta "#bb9af7"
        cyan "#7dcfff"
        white "#c0caf5"
        orange "#ff9e64"
    }
}
```

## 主な設定

- `pane_frames false`: ペインタイトルを非表示、最小限の区切り線のみ
- `cwd "."`: 起動ディレクトリを全ペインに継承
- `default_tab_template { children }`: タブバーを非表示

## キーバインド（デフォルト）

| キー | 機能 |
|------|------|
| `Alt + h/j/k/l` | ペイン間移動 |
| `Ctrl + p` | ペインモード |
| `Ctrl + t` | タブモード |
| `Ctrl + n` | リサイズモード |
| `Ctrl + q` | 終了 |

## 関連ツール

- [lazygit](https://github.com/jesseduffield/lazygit): Git TUI クライアント
- [Claude Code](https://claude.ai/code): Anthropic の CLI ツール

## トラブルシューティング

### 左ペインがホームディレクトリで開く

セッションをクリアして再起動:

```bash
zellij kill-all-sessions
cd /path/to/project
zellij --layout claude-code
```

### ペイン間の区切り線が見えない

`config.kdl` で `pane_frames` を確認:

```kdl
pane_frames false  // 最小限の区切り線
pane_frames true   // タイトル付きフレーム
```
