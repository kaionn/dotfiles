#!/usr/bin/env node
/**
 * Claude Code Session Logger (Lightweight)
 *
 * SessionEnd フックで実行され、セッション情報を pending ディレクトリに保存する
 * Ollama による要約生成は別のバッチ処理スクリプトで行う
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import path from "node:path";
import os from "node:os";

const PENDING_DIR = path.join(os.homedir(), ".claude", "session-logs", "pending");

/**
 * メイン処理
 */
async function main() {
  try {
    // ディレクトリ確認・作成
    if (!existsSync(PENDING_DIR)) {
      mkdirSync(PENDING_DIR, { recursive: true });
    }

    // フック入力を読み込み
    const input = JSON.parse(readFileSync(process.stdin.fd, "utf8"));

    if (!input.transcript_path) {
      console.log("No transcript path provided");
      process.exit(0);
    }

    // transcript パスを解決
    const homeDir = os.homedir();
    let transcriptPath = input.transcript_path;
    if (transcriptPath.startsWith("~/")) {
      transcriptPath = path.join(homeDir, transcriptPath.slice(2));
    }

    // セキュリティチェック: ~/.claude/projects 配下のみ許可
    const allowedBase = path.join(homeDir, ".claude", "projects");
    const absolutePath = path.resolve(transcriptPath);

    if (!absolutePath.startsWith(allowedBase)) {
      console.log(`Skipping: path outside allowed directory`);
      process.exit(0);
    }

    if (!existsSync(absolutePath)) {
      console.log(`Transcript file not found: ${absolutePath}`);
      process.exit(0);
    }

    // セッション情報を保存
    const now = new Date();
    const timestamp = now.toISOString().replace(/[:.]/g, "-");
    const sessionId = input.session_id || "unknown";
    const filename = `${timestamp}_${sessionId}.json`;
    const outputPath = path.join(PENDING_DIR, filename);

    const sessionData = {
      session_id: sessionId,
      cwd: input.cwd || process.cwd(),
      transcript_path: absolutePath,
      ended_at: now.toISOString(),
      project_name: path.basename(input.cwd || process.cwd())
    };

    writeFileSync(outputPath, JSON.stringify(sessionData, null, 2));
    console.log(`Session saved: ${filename}`);
  } catch (error) {
    console.error(`Session logger error: ${error.message}`);
    process.exit(1);
  }
}

main();
