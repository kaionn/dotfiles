# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## グローバル設定ディレクトリ

このディレクトリ (`~/.claude`) はグローバルな Claude Code 設定を管理します。

### ディレクトリ構成

- `commands/` - カスタムスラッシュコマンド
- `hooks/` - イベント駆動のスクリプト（Stop イベント時の通知など）
- `plugins/` - インストール済みプラグイン
- `settings.json` - グローバル設定（モデル、権限、有効なプラグイン）

### カスタムコマンド

主要なスラッシュコマンド:
- `/ask` - 質問に対する調査と回答（`./tmp/context.md` を読み込む）
- `/instruct` - 実装指示の実行（`./tmp/context.md` から複数指示を処理）
- `/revise` - 実装計画の修正（`./tmp/plan.md` を更新）
- `/recap <session-id>` - セッションの振り返りレポート作成
- `/setup-precommit` - husky と lint-staged の設定

### コマンドのパターン

カスタムコマンドは共通のパターンに従う:
1. `./tmp/context.md` から入力を読み込む
2. サブエージェントで調査を実行（Context7 MCP、Serena MCP を活用）
3. TodoWrite でタスク管理
4. 完了後にコミット

## 日本語ドキュメントのフォーマット

### textlint による自動フォーマット

日本語のマークダウンファイルを扱うプロジェクトでは、textlint を使用して文書品質を保ちます。

セットアップ:
```bash
npm install --save-dev textlint textlint-rule-preset-ja-spacing
```

使用方法:
```bash
npm run textlint        # チェックのみ
npm run textlint:fix    # 自動修正
```

運用ルール:
- マークダウンファイル編集後は `npm run textlint:fix` を実行する
- 全角文字と半角文字の間にスペースが自動挿入される

## マークダウン記法のガイドライン

太字 (`**text**`) は可読性を下げるため避ける。強調が必要な場合は、見出しレベルの調整やリスト構造で表現する。

## コミットメッセージ

- 日本語で記述する
- 変更内容を簡潔に説明する
- 「なぜ」変更したかを重視する

## セッション終了時のメモ

セッション終了時、ユーザーから求められた場合や、重要な知見がある場合は以下を記録する:

- つまずいた点、エラー、困った箇所
- 解決策や回避策
- 次回以降に役立つ知見

記録先: `~/.claude/rules/` 内の適切なファイル（恒久的な知見）、またはプロジェクト固有の `CLAUDE.md`

## rules ディレクトリ

`~/.claude/rules/` に恒久的な知見やワークフローを分割して保存:

- `daily-log-workflow.md` - デイリーログ自動生成の手順
- `local-llm-benchmark.md` - ローカル Vision LLM のベンチマーク結果

セッションログが蓄積した場合は、汎用的な知見を rules/ に移動して整理する。
