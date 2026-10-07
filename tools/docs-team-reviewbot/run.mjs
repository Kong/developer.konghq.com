#!/usr/bin/env node
// docs-team-reviewbot entry point. Advisory only: posts inline comments, never
// approves, never requests changes. Failures never fail the PR.
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { pathToFileURL } from "node:url";
import Anthropic from "@anthropic-ai/sdk";
import { LIMITS, MODEL, isReviewable } from "./src/config.mjs";
import { parseDiff, annotate } from "./src/diff.mjs";
import { loadSystem, buildUserContent } from "./src/prompt.mjs";
import { reviewPR } from "./src/review.mjs";
import { validateFindings, computeVerdictIfLive } from "./src/validate.mjs";
import { renderBody, fingerprint, parseMarker } from "./src/render.mjs";
import { getPR, listReviewComments, postComments } from "./src/github.mjs";

const exec = promisify(execFile);

// Pure: turn kept findings into API comments, skipping ones already posted.
export function planComments(kept, existingFingerprints, headSha) {
  const out = [];
  const skipped = [];
  for (const f of kept) {
    const fp = fingerprint(f);
    if (existingFingerprints.has(fp)) {
      skipped.push({ file: f.file, rule: f.rule, reason: "already posted" });
      continue;
    }
    out.push({ path: f.file, line: f.line, start_line: f.start_line ?? null, body: renderBody(f, headSha), fp, rule: f.rule });
  }
  return { comments: out, skipped };
}

function need(name) {
  const v = process.env[name];
  if (!v) throw new Error(`missing env ${name}`);
  return v;
}

async function main() {
  const repo = need("REPO");
  const prNumber = Number(need("PR_NUMBER"));
  const baseSha = need("BASE_SHA");
  const headSha = need("HEAD_SHA");
  const dryRun = process.env.DRY_RUN !== "false" || !process.env.POST_TOKEN; // dry run unless explicitly turned off
  const repoRoot = process.cwd();
  const outDir = process.env.OUT_DIR || join(tmpdir(), "reviewbot-out");
  await mkdir(outDir, { recursive: true });

  const runLog = { pr: prNumber, head: headSha, base: baseSha, model: MODEL, dry_run: dryRun, started_at: new Date().toISOString() };
  const finish = async (extra) => {
    Object.assign(runLog, extra, { finished_at: new Date().toISOString() });
    await writeFile(join(outDir, "run-log.json"), JSON.stringify(runLog, null, 2));
    console.log(`docs-team-reviewbot: ${runLog.outcome}${runLog.posted != null ? `, posted ${runLog.posted}` : ""}`);
  };

  const { stdout: patch } = await exec("git", ["diff", "--unified=3", "--no-color", "--no-ext-diff", `${baseSha}...${headSha}`, "--", "app"], {
    maxBuffer: 100_000_000,
  });
  const files = parseDiff(patch);
  const paths = [...files.keys()].filter(isReviewable);
  for (const p of [...files.keys()]) if (!paths.includes(p)) files.delete(p);
  if (!paths.length) return finish({ outcome: "skipped: no reviewable files" });
  const annotated = annotate(files, paths);
  if (annotated.length > LIMITS.maxDiffChars) return finish({ outcome: "skipped: diff too large", diff_chars: annotated.length });

  // Neither token is ever given to the model or its tools. GITHUB_TOKEN is read-only
  // (PR metadata, existing comments). POST_TOKEN is the comment-only App token and
  // is only needed outside dry-run mode.
  const ghToken = process.env.GITHUB_TOKEN;
  const postToken = process.env.POST_TOKEN;
  let meta = { title: "", body: "", user: { login: "" }, labels: [] };
  if (ghToken) meta = await getPR(ghToken, repo, prNumber);
  if (meta.draft) return finish({ outcome: "skipped: draft PR" });

  const client = new Anthropic({ maxRetries: 3, timeout: 10 * 60 * 1000 });
  let review;
  try {
    review = await reviewPR({
      client,
      system: await loadSystem(),
      userContent: buildUserContent({
        title: meta.title,
        body: meta.body,
        author: meta.user?.login,
        labels: (meta.labels || []).map((l) => l.name),
        paths,
        annotatedDiff: annotated,
      }),
      repoRoot,
      log: (m) => console.log(m),
    });
  } catch (e) {
    console.log(`::warning::docs-team-reviewbot model call failed: ${e.status ?? ""} ${String(e.message).slice(0, 200)}`);
    return finish({ outcome: "error: model call failed", error: String(e.message).slice(0, 500) });
  }
  const meterd = { usage: review.usage, tool_calls: review.toolCalls, turns: review.turns, fallback_ran: review.fallbackRan ?? false };
  if (review.status !== "ok") return finish({ outcome: `no review: ${review.status}`, ...meterd });

  const { kept, dropped } = validateFindings(review.result, files);
  const verdicts = { model_verdict_if_live: review.result.verdict_if_live ?? null, computed_verdict_if_live: computeVerdictIfLive(kept) };

  let posted = 0;
  let skipped = [];
  let failed = [];
  if (kept.length && !dryRun && ghToken && postToken) {
    // Do not comment on a stale commit if the author pushed while we were running.
    const current = await getPR(ghToken, repo, prNumber);
    if (current.head.sha !== headSha) {
      return finish({ outcome: "skipped: head moved during review", ...meterd, ...verdicts, kept, dropped });
    }
    const existing = new Set((await listReviewComments(ghToken, repo, prNumber)).map((c) => parseMarker(c.body)?.fp).filter(Boolean));
    const plan = planComments(kept, existing, headSha);
    skipped = plan.skipped;
    if (plan.comments.length) {
      const r = await postComments(postToken, repo, prNumber, headSha, plan.comments);
      posted = r.posted;
      failed = r.failed;
    }
  }
  return finish({ outcome: kept.length ? (dryRun ? "dry run" : "posted") : "silent: no findings", posted, ...meterd, ...verdicts, kept, dropped, skipped, failed });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((e) => {
    console.error(`::warning::docs-team-reviewbot failed: ${String(e.message).slice(0, 300)}`);
    process.exit(process.env.REVIEWBOT_STRICT === "true" ? 1 : 0);
  });
}
