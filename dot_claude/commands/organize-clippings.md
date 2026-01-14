# クリッピング整理・タグ標準化

Clippings ディレクトリのファイルをコンテンツに基づいて 01_sources の適切なサブディレクトリに振り分け、タグを標準化します。

**作業ディレクトリ:** `/Users/aucks/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main`

以下のすべてのパスは上記ディレクトリからの相対パスです。

**オプション実行モード:**

- `--tags-only`: ファイル移動せず、タグ標準化のみ実行
- `--move-only`: タグはそのまま、ファイル移動のみ実行
- デフォルト: 移動とタグ標準化を両方実行

以下の手順で実行してください：

&#35;&#35; Step 1: Clippings ディレクトリの内容を確認

Clippings ディレクトリ内のすべての Markdown ファイルをリストアップし、各ファイルの内容とタグを確認します。

&#35;&#35; Step 2: ファイルのカテゴリ分析

各ファイルの内容、タイトル、タグを分析して、以下のカテゴリに分類します：

&#35;&#35;&#35; 既存の 01_sources サブディレクトリ：

- **ai_engineering/**: AI エンジニアリング、Agentic Software Engineering、コンテキストエンジニアリング関連
- **ai_tools/**: Claude Code、Kiro、Gemini CLI、Cursor、Windsurf 等の AI コーディングツール
- **ai_tools_kiro_250724/**: Kiro 専用ドキュメント（既に多数存在）
- **business/**: ビジネスモデル、マーケティング、収益化、スタートアップ関連
- **clips/**: 短い記事クリップ、ブログ記事、一般的なウェブクリップ
- **references/**: 技術リファレンス、プログラミング言語、開発手法、ガイド類
- **tool_obsidian/**: Obsidian 関連のツールやワークフロー

上記に該当しない場合、新規で Folder を作成する。名前は適宜つけること

&#35;&#35; Step 3: ファイルの移動

各ファイルを適切なディレクトリに移動します：

&#96;&#96;&#96;&#96;bash

# 基本的な移動コマンド例

mv "Clippings/[ファイル名].md" "01_sources/[適切なカテゴリ]/[ファイル名].md"
&#96;&#96;&#96;&#96;

&#35;&#35; 分類ガイドライン：

1. **Kiro 関連** → `ai_tools/` または `ai_tools_kiro_250724/`（内容の詳細度による）
2. **Claude Code、Gemini CLI 等** → `ai_tools/`
3. **AI エージェント、開発手法論** → `ai_engineering/`
4. **ビジネス戦略、起業** → `business/`
5. **技術チュートリアル、MCP** → `references/`
6. **Web サービス開発** → `web_development/`（新規作成）
7. **プロダクト事例、失敗談** → `product_development/`（新規作成）
8. **一般的なクリップ** → `clips/`

&#35;&#35; Step 4: 必要に応じて新規ディレクトリ作成

01_sources 直下に新しいカテゴリが必要な場合は作成します：

&#96;&#96;&#96;&#96;bash
mkdir -p "01_sources/web_development"
mkdir -p "01_sources/product_development"
&#96;&#96;&#96;&#96;

&#35;&#35; Step 5: タグの標準化

各ファイル（移動した場合は移動先、`--tags-only`の場合は Clippings 内）について、`.claude/tag-list.md`に基づいてタグを標準化します：

**タグ標準化の詳細手順：**

1. **標準タグリストの参照**

   - `.claude/tag-list.md`から利用可能な標準タグを確認

2. **既存タグの分析**

   - 現在のタグを確認
   - `clippings`タグは削除対象としてマーク

3. **標準タグへのマッピング**

   - 既存タグを標準タグにマッピング
   - アンダースコア → ハイフン変換（claude_code → claude-code）
   - 日本語タグは標準リストの対応するものを使用

4. **新規タグの追加**

   - コンテンツ内容に基づいて適切な標準タグを 4-6 個程度追加
   - 以下のカテゴリから選択：
     - **AI・開発**: ai-tools, claude-code, kiro, ai-development, ai-agents
     - **技術**: React, TypeScript, engineering, software-development, frontend
     - **ビジネス**: startup, monetization, marketing, indie-dev, entrepreneurship
     - **コンテンツタイプ**: tutorial, case-study, japanese, review, documentation

5. **タグの更新・整理**
   - フロントマターの tags セクションを更新
   - 重複を除去し、アルファベット順にソート
   - 既存の有用な情報は保持

**重要なマッピング例：**

- `"claude-code"` → claude-code
- `"kiro"` → kiro
- `"AI"` → ai-development, ai-tools, ai-agents（文脈依存）
- `"security"` → security, ai-security
- `"開発効率化"` → 開発効率化（日本語版を標準リストから使用）
- `"IDE"` → 具体的なツール名に置換または削除

&#35;&#35; Step 6: 整理結果の確認

移動後、以下を確認します：

- Clippings ディレクトリが空になっていること
- 各ファイルが適切なカテゴリに配置されていること
- 全ファイルのタグが標準化されていること

&#35;&#35; Step 7: 完了報告

移動したファイル数、各カテゴリへの振り分け結果、タグ標準化の結果をレポートします。

---

**注意事項：**

- ディレクトリ階層は 01_sources 直下の 1 階層のみ（最大深度：01_sources/category/）
- ファイル名にスペースや特殊文字が含まれる場合は適切にクォート
- 移動前にバックアップを推奨
- 既存の有用な情報は保持し、タグのみ標準化すること
- `.claude/tag-list.md`にない重要なタグが見つかった場合は、tag-list に追加を検討すること
