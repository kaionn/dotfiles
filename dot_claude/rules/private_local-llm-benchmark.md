# ローカル Vision LLM ベンチマーク

M3 Pro + 36GB RAM 環境での Ollama Vision モデル比較結果。

## テスト条件

- 画像: Claude Code セッションのスクリーンショット（1024px にリサイズ）
- タスク: 画面が黒いか判定 + アプリ識別
- 日付: 2026-01-06

## 結果

| モデル | 処理時間 | 精度 | モデルサイズ | 備考 |
|--------|----------|------|--------------|------|
| moondream | 79秒 | 低 | 1.7GB | 高速だが黒画面誤判定あり |
| llava:7b | 162秒 | 低 | 4.7GB | 「画面オフ」と誤判定 |
| llava:13b | 325秒 | 中 | 8.0GB | VS Code を正しく識別 |
| minicpm-v | 568秒 | 高 | 5.5GB | Obsidian を正確に識別 |

## 推奨

- 高速分類（Phase 1）: moondream + ファイルサイズフィルタ
- 詳細分析（Phase 2）: Claude（API または Claude Code）

## モデルインストール

```bash
ollama pull moondream
ollama pull llava:7b
ollama pull llava:13b
ollama pull minicpm-v
```

## 知見

1. moondream は速いが精度に課題 → ファイルサイズ事前フィルタで補完
2. minicpm-v は精度高いが遅すぎる（568秒/画像）
3. ハイブリッド方式が最適解（ローカル LLM + Claude）
