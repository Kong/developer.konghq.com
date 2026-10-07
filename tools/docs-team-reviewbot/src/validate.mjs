// Enforces the rubric's hard rules in code, so a model slip cannot post a
// finding the rubric forbids. Dropped findings are returned with reasons for
// the run log.
import { LIMITS, TIER_ORDER, SEVERITY_ORDER, isReviewable } from "./config.mjs";

const nonEmpty = (s) => typeof s === "string" && s.trim().length > 0;

function checkOne(f, files, reasoningChecks) {
  if (!f || typeof f !== "object") return "not an object";
  if (!nonEmpty(f.file) || !isReviewable(f.file)) return "file not reviewable";
  const diffFile = files.get(f.file);
  if (!diffFile) return "file not in diff";
  if (!TIER_ORDER.includes(f.tier)) return "bad tier";
  if (!SEVERITY_ORDER.includes(f.severity)) return "bad severity";
  if (!nonEmpty(f.rule)) return "missing rule";
  if (!nonEmpty(f.comment) || f.comment.length > 800) return "bad comment";
  if (typeof f.confidence !== "number" || f.confidence < LIMITS.minConfidence) return "confidence below threshold";
  if (!Number.isInteger(f.line) || !diffFile.added.has(f.line)) return "line is not an added line";
  if (f.start_line != null) {
    if (!Number.isInteger(f.start_line) || f.start_line > f.line) return "bad start_line";
    for (let n = f.start_line; n <= f.line; n++) if (!diffFile.added.has(n)) return "range includes unchanged line";
  }
  const needsSuggestion = f.tier === "always_flag" || f.tier === "flag_softly";
  if (needsSuggestion) {
    if (!nonEmpty(f.suggestion)) return "suggestion required for this tier";
    if (f.suggestion.includes("```")) return "suggestion contains a code fence";
  }
  if (f.tier === "human_only") {
    for (const k of ["what_to_check", "why", "where_to_verify", "inconsistency"]) {
      if (!nonEmpty(f[k])) return `human_only missing ${k}`;
    }
  }
  return null;
}

export function validateFindings(result, files) {
  const raw = Array.isArray(result?.findings) ? result.findings : [];
  const checks = Array.isArray(result?.reasoning_checks) ? result.reasoning_checks : [];
  const dropped = [];
  let kept = [];
  const seen = new Set();
  for (const f of raw) {
    const why = checkOne(f, files, checks);
    if (why) {
      dropped.push({ finding: f, reason: why });
      continue;
    }
    const key = `${f.file}:${f.line}:${f.rule}`;
    if (seen.has(key)) {
      dropped.push({ finding: f, reason: "duplicate" });
      continue;
    }
    seen.add(key);
    const out = { ...f };
    if (out.tier === "optional" || out.tier === "human_only") out.suggestion = null;
    // blocking needs a confirmed/contradicted check that cites a file
    if (out.severity === "blocking") {
      const ok = checks.some((c) => (c.result === "confirmed" || c.result === "contradicted") && Array.isArray(c.files) && c.files.length);
      if (!ok) out.severity = "should_fix";
    }
    kept.push(out);
  }
  kept.sort(
    (a, b) =>
      SEVERITY_ORDER.indexOf(a.severity) - SEVERITY_ORDER.indexOf(b.severity) ||
      TIER_ORDER.indexOf(a.tier) - TIER_ORDER.indexOf(b.tier) ||
      b.confidence - a.confidence,
  );
  // caps, applied in priority order
  let human = 0;
  let soft = 0;
  const capped = [];
  for (const f of kept) {
    if (f.tier === "human_only") {
      if (human >= LIMITS.maxHumanOnly) { dropped.push({ finding: f, reason: "cap: human_only" }); continue; }
      human++;
    } else if (f.tier === "flag_softly" || f.tier === "optional") {
      if (soft >= LIMITS.maxSoftAndOptional) { dropped.push({ finding: f, reason: "cap: soft and optional" }); continue; }
      soft++;
    }
    if (capped.length >= LIMITS.maxFindings) { dropped.push({ finding: f, reason: "cap: total" }); continue; }
    capped.push(f);
  }
  return { kept: capped, dropped };
}

// Deterministic version of the rubric's verdict logic. Logged only; never posted.
export function computeVerdictIfLive(kept) {
  if (kept.some((f) => f.severity === "blocking")) return "request_changes";
  if (kept.some((f) => f.tier === "human_only" && f.impact === "high")) return "needs_human";
  if (kept.filter((f) => f.severity === "should_fix").length <= 3) return "approve";
  return "comment";
}
