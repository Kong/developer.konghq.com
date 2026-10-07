// Unified-diff parsing. Produces, per file, the set of added line numbers
// (new-file numbering) and a line-numbered rendering for the model.

export function parseDiff(patch) {
  const files = new Map();
  let cur = null;
  let newLine = 0;
  for (const raw of patch.split("\n")) {
    if (raw.startsWith("diff --git ")) {
      cur = null;
      continue;
    }
    if (raw.startsWith("+++ ")) {
      const p = raw.slice(4).trim();
      if (p === "/dev/null") {
        cur = null;
      } else {
        const path = p.replace(/^b\//, "");
        cur = { path, added: new Set(), lines: [] };
        files.set(path, cur);
      }
      continue;
    }
    if (raw.startsWith("--- ") || raw.startsWith("index ") || raw.startsWith("new file") ||
        raw.startsWith("deleted file") || raw.startsWith("similarity") || raw.startsWith("rename ") ||
        raw.startsWith("old mode") || raw.startsWith("new mode") || raw.startsWith("Binary files")) {
      continue;
    }
    if (!cur) continue;
    const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/.exec(raw);
    if (hunk) {
      newLine = Number(hunk[1]);
      cur.lines.push({ kind: "hunk", text: raw });
      continue;
    }
    if (raw.startsWith("\\")) continue; // "\ No newline at end of file"
    if (raw.startsWith("+")) {
      cur.added.add(newLine);
      cur.lines.push({ kind: "add", n: newLine, text: raw.slice(1) });
      newLine++;
    } else if (raw.startsWith("-")) {
      cur.lines.push({ kind: "del", text: raw.slice(1) });
    } else if (raw.startsWith(" ")) {
      cur.lines.push({ kind: "ctx", n: newLine, text: raw.slice(1) });
      newLine++;
    }
  }
  return files;
}

// Render for the model: every new-file line carries its number, so the model
// never has to count from hunk headers.
export function annotate(files, paths) {
  const out = [];
  for (const path of paths) {
    const f = files.get(path);
    if (!f) continue;
    out.push(`=== FILE ${path} ===`);
    for (const l of f.lines) {
      if (l.kind === "hunk") out.push(l.text);
      else if (l.kind === "add") out.push(`L${l.n}: + ${l.text}`);
      else if (l.kind === "ctx") out.push(`L${l.n}:   ${l.text}`);
      else out.push(`     - ${l.text}`);
    }
  }
  return out.join("\n");
}
