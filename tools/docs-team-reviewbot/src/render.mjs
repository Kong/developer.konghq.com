import { createHash } from "node:crypto";

export const MARKER_PREFIX = "<!-- docs-team-reviewbot";
const FOOTER = "_docs-team-reviewbot, advisory only. React with 👍 if this helped, 👎 if not._";

export function fingerprint(f) {
  const basis = `${f.file}|${f.rule}|${(f.suggestion ?? f.comment).replace(/\s+/g, " ").trim()}`;
  return createHash("sha1").update(basis).digest("hex").slice(0, 12);
}

export function renderBody(f, headSha) {
  const parts = [f.comment.trim()];
  if (f.suggestion != null) parts.push("```suggestion\n" + f.suggestion.replace(/\n+$/, "") + "\n```");
  if (Array.isArray(f.also_at) && f.also_at.length) parts.push(`Same pattern at lines ${f.also_at.join(", ")}.`);
  parts.push(FOOTER);
  parts.push(`${MARKER_PREFIX} rule=${f.rule} fp=${fingerprint(f)} run=${headSha.slice(0, 7)} -->`);
  return parts.join("\n\n");
}

export function parseMarker(body) {
  const m = /<!-- docs-team-reviewbot rule=(\S+) fp=([0-9a-f]+) run=([0-9a-f]+) -->/.exec(body || "");
  return m ? { rule: m[1], fp: m[2], run: m[3] } : null;
}
