// Read-only repo tools for the model. Everything is sandboxed to a few roots
// inside the checkout. No shell, no network, no secrets in the child env.
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { readFile, readdir, realpath, stat } from "node:fs/promises";
import { resolve, relative, sep } from "node:path";
import { LIMITS } from "./config.mjs";

const run = promisify(execFile);
const ALLOWED_ROOTS = ["app", "docs", "api-specs"];

export const TOOL_DEFS = [
  {
    name: "read_file",
    description:
      "Read a text file from the repo checkout (PR head). Paths are relative to the repo root and limited to app/, docs/ and api-specs/. Returns numbered lines. Use start_line/end_line for large files.",
    input_schema: {
      type: "object",
      properties: {
        path: { type: "string" },
        start_line: { type: "integer", minimum: 1 },
        end_line: { type: "integer", minimum: 1 },
      },
      required: ["path"],
    },
  },
  {
    name: "grep",
    description:
      "Search the repo (git grep, fixed-string unless regex=true). Optional path prefix under app/, docs/ or api-specs/. Returns up to 60 matching lines as path:line:text.",
    input_schema: {
      type: "object",
      properties: {
        pattern: { type: "string" },
        path: { type: "string" },
        regex: { type: "boolean" },
      },
      required: ["pattern"],
    },
  },
  {
    name: "list_dir",
    description: "List a directory (relative to the repo root, limited to app/, docs/ and api-specs/).",
    input_schema: { type: "object", properties: { path: { type: "string" } }, required: ["path"] },
  },
];

// Child processes get a minimal environment: no API keys, no tokens.
export function cleanEnv() {
  return { PATH: process.env.PATH, HOME: process.env.HOME, LC_ALL: "C" };
}

export async function safePath(repoRoot, p) {
  if (typeof p !== "string" || p.includes("\0")) throw new Error("invalid path");
  const root = await realpath(repoRoot);
  const full = resolve(root, p);
  let real;
  try {
    real = await realpath(full);
  } catch {
    throw new Error(`not found: ${p}`);
  }
  const rel = relative(root, real);
  if (rel.startsWith("..") || rel === "" ) throw new Error("path outside repo");
  const top = rel.split(sep)[0];
  if (!ALLOWED_ROOTS.includes(top)) throw new Error(`path must be under ${ALLOWED_ROOTS.join(", ")}`);
  if (rel.split(sep).some((s) => s === ".git" || s.startsWith(".env"))) throw new Error("blocked path");
  return { real, rel: rel.split(sep).join("/") };
}

function clip(s, max = LIMITS.maxToolResultChars) {
  return s.length > max ? s.slice(0, max) + `\n[truncated at ${max} chars]` : s;
}

export async function runTool(repoRoot, name, input) {
  switch (name) {
    case "read_file": {
      const { real } = await safePath(repoRoot, input.path);
      const st = await stat(real);
      if (!st.isFile()) throw new Error("not a file");
      if (st.size > 2_000_000) throw new Error("file too large; use grep");
      const lines = (await readFile(real, "utf8")).split("\n");
      const start = Math.max(1, input.start_line ?? 1);
      const end = Math.min(lines.length, input.end_line ?? lines.length);
      return clip(lines.slice(start - 1, end).map((l, i) => `${start + i}: ${l}`).join("\n"));
    }
    case "grep": {
      if (typeof input.pattern !== "string" || !input.pattern) throw new Error("pattern required");
      let scope = ALLOWED_ROOTS;
      if (input.path) scope = [(await safePath(repoRoot, input.path)).rel];
      const args = ["grep", "-n", "-I", "--no-color", "-m", "20", input.regex ? "-E" : "-F", "-e", input.pattern, "--", ...scope];
      try {
        const { stdout } = await run("git", args, { cwd: repoRoot, env: cleanEnv(), maxBuffer: 5_000_000, timeout: 20_000 });
        return clip(stdout.split("\n").slice(0, 60).join("\n")) || "(no matches)";
      } catch (e) {
        if (e.code === 1) return "(no matches)";
        throw new Error("grep failed");
      }
    }
    case "list_dir": {
      const { real } = await safePath(repoRoot, input.path);
      const entries = await readdir(real, { withFileTypes: true });
      return clip(entries.slice(0, 300).map((e) => e.name + (e.isDirectory() ? "/" : "")).join("\n"));
    }
    default:
      throw new Error(`unknown tool ${name}`);
  }
}
