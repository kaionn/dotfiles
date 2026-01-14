#!/usr/bin/env node
/**
 * Claude Code Daily Summary Generator
 *
 * 前日21:01〜当日21:00のセッションログを読み込み、
 * Ollamaで要約を生成してObsidianに記録する
 *
 * 使用方法:
 *   node daily-summary.mjs             # 今日の分を処理
 *   node daily-summary.mjs --backfill  # 過去分も含めてすべて処理
 *   node daily-summary.mjs --test      # 設定確認
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, renameSync } from "node:fs";
import path from "node:path";
import os from "node:os";
import https from "node:https";
import http from "node:http";

// ディレクトリ設定
const BASE_DIR = path.join(os.homedir(), ".claude", "session-logs");
const PENDING_DIR = path.join(BASE_DIR, "pending");
const PROCESSED_DIR = path.join(BASE_DIR, "processed");

// 設定読み込み
const configPath = path.join(path.dirname(new URL(import.meta.url).pathname), "config.json");
const config = JSON.parse(readFileSync(configPath, "utf8"));

/**
 * 日付をフォーマット
 */
function formatDate(date) {
  return date.toISOString().slice(0, 10);
}

/**
 * 前日21:01〜当日21:00の範囲を計算
 */
function getTimeRange() {
  const now = new Date();
  const hour = now.getHours();

  // 21:00以降なら今日の範囲、それ以前なら昨日の範囲
  const targetDate = hour >= 21 ? now : new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const startDate = new Date(targetDate);
  startDate.setDate(startDate.getDate() - 1);
  startDate.setHours(21, 1, 0, 0);

  const endDate = new Date(targetDate);
  endDate.setHours(21, 0, 0, 0);

  return { start: startDate, end: endDate, targetDate };
}

/**
 * テンプレートからデイリーノートを生成
 */
function generateDailyNoteFromTemplate(template, date) {
  const dateStr = formatDate(date);
  const prevDate = formatDate(new Date(date.getTime() - 24 * 60 * 60 * 1000));
  const nextDate = formatDate(new Date(date.getTime() + 24 * 60 * 60 * 1000));

  return template
    .replace(/\{\{DATE:YYYY-MM-DD\}\}/g, dateStr)
    .replace(/\{\{date:YYYY-MM-DD\|offset:-1d\}\}/g, prevDate)
    .replace(/\{\{date:YYYY-MM-DD\|offset:1d\}\}/g, nextDate);
}

/**
 * pendingディレクトリから対象セッションを取得
 */
function getPendingSessions(start, end) {
  if (!existsSync(PENDING_DIR)) {
    return [];
  }

  const files = readdirSync(PENDING_DIR).filter(f => f.endsWith(".json"));
  const sessions = [];

  for (const file of files) {
    try {
      const data = JSON.parse(readFileSync(path.join(PENDING_DIR, file), "utf8"));
      const endedAt = new Date(data.ended_at);

      if (endedAt >= start && endedAt <= end) {
        sessions.push({ ...data, filename: file });
      }
    } catch (e) {
      console.error(`Failed to parse ${file}: ${e.message}`);
    }
  }

  return sessions.sort((a, b) => new Date(a.ended_at) - new Date(b.ended_at));
}

/**
 * pendingディレクトリから全セッションを日付ごとにグループ化して取得
 */
function getAllPendingSessionsByDate() {
  if (!existsSync(PENDING_DIR)) {
    return new Map();
  }

  const files = readdirSync(PENDING_DIR).filter(f => f.endsWith(".json"));
  const sessionsByDate = new Map();

  for (const file of files) {
    try {
      const data = JSON.parse(readFileSync(path.join(PENDING_DIR, file), "utf8"));
      const endedAt = new Date(data.ended_at);

      // セッション終了時刻から対象日を計算（21:00基準）
      // 21:00以降のセッションはその日、21:00以前は前日に属する
      const hour = endedAt.getHours();
      let targetDate;
      if (hour >= 21) {
        targetDate = formatDate(endedAt);
      } else {
        targetDate = formatDate(endedAt);
      }

      if (!sessionsByDate.has(targetDate)) {
        sessionsByDate.set(targetDate, []);
      }
      sessionsByDate.get(targetDate).push({ ...data, filename: file });
    } catch (e) {
      console.error(`Failed to parse ${file}: ${e.message}`);
    }
  }

  // 各日付内でセッションを時間順にソート
  for (const [date, sessions] of sessionsByDate) {
    sessions.sort((a, b) => new Date(a.ended_at) - new Date(b.ended_at));
  }

  return sessionsByDate;
}

/**
 * transcript を読み込んで会話内容を抽出
 */
function loadTranscript(transcriptPath) {
  if (!existsSync(transcriptPath)) {
    return [];
  }

  const lines = readFileSync(transcriptPath, "utf8")
    .split("\n")
    .filter(line => line.trim());

  const messages = [];
  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      if (entry.type === "user" || entry.type === "assistant") {
        messages.push(entry);
      }
    } catch {
      // 無効な行はスキップ
    }
  }

  return messages;
}

/**
 * 会話内容をテキスト形式に変換
 */
function formatTranscriptForSummary(messages) {
  const formatted = [];

  for (const msg of messages) {
    const role = msg.type === "user" ? "User" : "Assistant";
    let content = "";

    if (typeof msg.message?.content === "string") {
      content = msg.message.content;
    } else if (Array.isArray(msg.message?.content)) {
      content = msg.message.content
        .filter(c => c.type === "text")
        .map(c => c.text)
        .join("\n");
    }

    if (content) {
      formatted.push(`[${role}]\n${content.slice(0, 1500)}${content.length > 1500 ? "..." : ""}`);
    }
  }

  // 最大メッセージ数を制限
  const maxMessages = 15;
  if (formatted.length > maxMessages) {
    const first = formatted.slice(0, 4);
    const last = formatted.slice(-8);
    return [...first, "\n[... 中略 ...]\n", ...last].join("\n\n");
  }

  return formatted.join("\n\n");
}

/**
 * Ollama API にリクエストを送信
 */
function ollamaRequest(body) {
  return new Promise((resolve, reject) => {
    const ollamaUrl = config.ollama?.baseUrl || "http://localhost:11434";
    const url = new URL("/api/chat", ollamaUrl);

    const options = {
      method: "POST",
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      headers: {
        "Content-Type": "application/json"
      }
    };

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`Ollama API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on("error", reject);
    req.write(JSON.stringify(body));
    req.end();
  });
}

/**
 * Ollama でセッション要約を生成
 */
async function generateSummary(sessions) {
  const model = config.ollama?.model || "qwen2.5:7b";

  // 全セッションの会話をまとめる
  const allTranscripts = [];
  for (const session of sessions) {
    const messages = loadTranscript(session.transcript_path);
    if (messages.length >= 2) {
      const transcript = formatTranscriptForSummary(messages);
      allTranscripts.push({
        project: session.project_name,
        time: new Date(session.ended_at).toLocaleTimeString("ja-JP", { hour: "2-digit", minute: "2-digit" }),
        content: transcript
      });
    }
  }

  if (allTranscripts.length === 0) {
    return null;
  }

  const sessionsText = allTranscripts.map(s =>
    `### ${s.time} - ${s.project}\n\n${s.content}`
  ).join("\n\n---\n\n");

  const prompt = `以下は今日の Claude Code セッションの会話履歴です。2つの要約を JSON 形式で生成してください。

## 会話履歴
${sessionsText}

## 出力形式
以下の JSON 形式で出力してください：

\`\`\`json
{
  "dailyLog": {
    "entries": [
      {
        "time": "HH:MM",
        "project": "プロジェクト名",
        "summary": "1行の簡潔な要約（何をしたか）",
        "tags": ["タグ1", "タグ2"]
      }
    ]
  },
  "knowledge": {
    "shouldCreate": true/false,
    "title": "ナレッジノートのタイトル（重要な技術的内容がある場合）",
    "content": "マークダウン形式の詳細な解説"
  }
}
\`\`\`

ルール:
- dailyLog.entries は各セッションの要約を時間順に記述
- summary は日本語で簡潔に
- knowledge.shouldCreate はコード生成や重要な技術的内容がある場合のみ true
- JSON のみを出力`;

  const response = await ollamaRequest({
    model,
    messages: [{ role: "user", content: prompt }],
    stream: false
  });

  const text = response.message?.content || "";

  // JSON を抽出
  let jsonStr = "";
  const codeBlockMatch = text.match(/```(?:json)?\s*\n?([\s\S]*?)\n?```/);
  if (codeBlockMatch) {
    jsonStr = codeBlockMatch[1].trim();
  } else {
    const braceMatch = text.match(/\{[\s\S]*\}/);
    if (braceMatch) {
      jsonStr = braceMatch[0];
    }
  }

  if (!jsonStr) {
    console.error("Failed to extract JSON from response");
    return null;
  }

  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    // 修復を試みる
    jsonStr = jsonStr.replace(/:\s*true\/false/g, ': false');
    jsonStr = jsonStr.replace(/,\s*([\]}])/g, '$1');
    try {
      return JSON.parse(jsonStr);
    } catch {
      console.error("JSON parse failed");
      return null;
    }
  }
}

/**
 * Obsidian REST API にリクエストを送信
 */
function obsidianRequest(method, endpoint, body = null, contentType = "text/markdown") {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint, config.obsidian.baseUrl);

    const headers = {
      "Authorization": `Bearer ${config.obsidian.apiKey}`
    };

    if (body) {
      headers["Content-Type"] = contentType;
    }

    const options = {
      method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      headers,
      rejectUnauthorized: false
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ status: res.statusCode, data });
        } else if (res.statusCode === 404) {
          resolve({ status: 404, data: null });
        } else {
          reject(new Error(`Obsidian API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on("error", reject);

    if (body) {
      req.write(body);
    }
    req.end();
  });
}

/**
 * Session Talk セクション内にエントリを挿入
 */
function insertIntoSessionTalkSection(content, logEntries) {
  const lines = content.split("\n");
  const result = [];
  let inSessionTalk = false;
  let inserted = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Session Talk セクションの開始を検出
    if (line.match(/^##\s+Session\s*Talk/i)) {
      inSessionTalk = true;
      result.push(line);
      continue;
    }

    // Session Talk セクション内で次のセクション（## で始まる行）を検出
    if (inSessionTalk && !inserted && line.match(/^##\s+/)) {
      // 次のセクションの前にエントリを挿入
      result.push(logEntries);
      result.push("");
      inserted = true;
      inSessionTalk = false;
    }

    // Session Talk セクション内で "- " のプレースホルダー行を検出
    if (inSessionTalk && !inserted && line.trim() === "-") {
      // プレースホルダーをエントリで置換
      result.push(logEntries);
      inserted = true;
      continue;
    }

    result.push(line);
  }

  // Session Talk セクションが最後のセクションだった場合
  if (inSessionTalk && !inserted) {
    result.push(logEntries);
  }

  return result.join("\n");
}

/**
 * デイリーノートに Session Talk を追記
 */
async function appendToSessionTalk(summary, targetDate) {
  const year = targetDate.getFullYear();
  const month = String(targetDate.getMonth() + 1).padStart(2, "0");
  const date = formatDate(targetDate);

  const dailyNotePath = config.paths.dailyNote
    .replace("{year}", String(year))
    .replace("{month}", month)
    .replace("{date}", date);

  // ログエントリを生成
  const logEntries = summary.dailyLog.entries.map(entry => {
    const tags = entry.tags.map(t => `#${t}`).join(" ");
    return `- 🤖 [${entry.time}] **${entry.project}**: ${entry.summary} ${tags}`;
  }).join("\n");

  try {
    // ファイル存在確認・取得
    let fileContent = "";
    const checkResult = await obsidianRequest("GET", `/vault/${encodeURIComponent(dailyNotePath)}`);

    if (checkResult.status === 404) {
      // テンプレートから作成
      console.log(`Creating daily note: ${dailyNotePath}`);
      const templateResult = await obsidianRequest("GET", `/vault/${encodeURIComponent(config.paths.dailyTemplate)}`);
      if (templateResult.status === 200 && templateResult.data) {
        fileContent = generateDailyNoteFromTemplate(templateResult.data, targetDate);
      } else {
        console.log("Template not found, skipping");
        return;
      }
    } else {
      fileContent = checkResult.data;
    }

    // Session Talk セクション内にエントリを挿入
    const updatedContent = insertIntoSessionTalkSection(fileContent, logEntries);

    // ファイルを更新
    await obsidianRequest("PUT", `/vault/${encodeURIComponent(dailyNotePath)}`, updatedContent);
    console.log(`Daily note updated: ${dailyNotePath}`);
  } catch (error) {
    console.error(`Failed to update daily note: ${error.message}`);
  }
}

/**
 * ナレッジノートを作成
 */
async function createKnowledgeNote(summary, targetDate) {
  if (!summary.knowledge.shouldCreate) {
    return;
  }

  const dateStr = formatDate(targetDate);
  const safeTitle = summary.knowledge.title
    .replace(/[/\\?%*:|"<>]/g, "-")
    .slice(0, 100);

  const filename = `${dateStr}-${safeTitle}.md`;
  const filepath = `${config.paths.knowledgeBase}/${filename}`;

  const frontmatter = `---
date: "${dateStr}"
tags:
  - claude-code
---

`;

  const content = frontmatter + summary.knowledge.content;

  try {
    await obsidianRequest("PUT", `/vault/${encodeURIComponent(filepath)}`, content);
    console.log(`Knowledge note created: ${filepath}`);
  } catch (error) {
    console.error(`Failed to create knowledge note: ${error.message}`);
  }
}

/**
 * 処理済みファイルを移動
 */
function moveToProcessed(sessions) {
  if (!existsSync(PROCESSED_DIR)) {
    mkdirSync(PROCESSED_DIR, { recursive: true });
  }

  for (const session of sessions) {
    const src = path.join(PENDING_DIR, session.filename);
    const dst = path.join(PROCESSED_DIR, session.filename);
    try {
      renameSync(src, dst);
    } catch (e) {
      console.error(`Failed to move ${session.filename}: ${e.message}`);
    }
  }
}

/**
 * 単一日付のセッションを処理
 */
async function processDateSessions(dateStr, sessions) {
  console.log(`\n=== Processing ${dateStr} (${sessions.length} sessions) ===`);

  // 要約を生成
  console.log("Generating summary with Ollama...");
  const summary = await generateSummary(sessions);

  if (!summary) {
    console.log(`Failed to generate summary for ${dateStr}`);
    return false;
  }

  // 対象日のDateオブジェクトを作成
  const targetDate = new Date(dateStr + "T12:00:00");

  // Obsidian に記録
  await appendToSessionTalk(summary, targetDate);
  await createKnowledgeNote(summary, targetDate);

  // 処理済みに移動
  moveToProcessed(sessions);

  console.log(`Completed: ${dateStr}`);
  return true;
}

/**
 * メイン処理
 */
async function main() {
  try {
    // テストモード
    if (process.argv.includes("--test")) {
      console.log("Test mode: configuration valid");
      console.log(`Obsidian URL: ${config.obsidian.baseUrl}`);
      console.log(`Ollama URL: ${config.ollama?.baseUrl || "http://localhost:11434"}`);
      console.log(`Ollama Model: ${config.ollama?.model || "qwen2.5:7b"}`);
      console.log(`Pending dir: ${PENDING_DIR}`);

      const { start, end, targetDate } = getTimeRange();
      console.log(`Time range: ${start.toISOString()} - ${end.toISOString()}`);
      console.log(`Target date: ${formatDate(targetDate)}`);

      const sessions = getPendingSessions(start, end);
      console.log(`Found ${sessions.length} sessions in range`);

      // バックフィル対象も表示
      const allSessions = getAllPendingSessionsByDate();
      console.log(`\nBackfill targets (${allSessions.size} dates):`);
      for (const [date, s] of [...allSessions.entries()].sort()) {
        console.log(`  ${date}: ${s.length} sessions`);
      }
      process.exit(0);
    }

    // バックフィルモード
    if (process.argv.includes("--backfill")) {
      console.log("=== Backfill Mode ===");
      const sessionsByDate = getAllPendingSessionsByDate();

      if (sessionsByDate.size === 0) {
        console.log("No pending sessions to process");
        process.exit(0);
      }

      console.log(`Found ${sessionsByDate.size} dates to process`);

      // 日付順にソートして処理
      const sortedDates = [...sessionsByDate.keys()].sort();
      let successCount = 0;
      let failCount = 0;

      for (const dateStr of sortedDates) {
        const sessions = sessionsByDate.get(dateStr);
        try {
          const success = await processDateSessions(dateStr, sessions);
          if (success) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (error) {
          console.error(`Error processing ${dateStr}: ${error.message}`);
          failCount++;
        }
      }

      console.log(`\n=== Backfill Complete ===`);
      console.log(`Success: ${successCount}, Failed: ${failCount}`);
      process.exit(failCount > 0 ? 1 : 0);
    }

    // 通常モード: 時間範囲を取得
    const { start, end, targetDate } = getTimeRange();
    console.log(`Processing sessions from ${start.toISOString()} to ${end.toISOString()}`);

    // 対象セッションを取得
    const sessions = getPendingSessions(start, end);
    console.log(`Found ${sessions.length} pending sessions`);

    if (sessions.length === 0) {
      console.log("No sessions to process");
      process.exit(0);
    }

    // 要約を生成
    console.log("Generating summary with Ollama...");
    const summary = await generateSummary(sessions);

    if (!summary) {
      console.log("Failed to generate summary");
      process.exit(1);
    }

    // Obsidian に記録
    await appendToSessionTalk(summary, targetDate);
    await createKnowledgeNote(summary, targetDate);

    // 処理済みに移動
    moveToProcessed(sessions);

    console.log("Daily summary completed");
  } catch (error) {
    console.error(`Daily summary error: ${error.message}`);
    process.exit(1);
  }
}

main();
