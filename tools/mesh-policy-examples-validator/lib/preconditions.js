import fs from "fs";
import path from "path";
import {
  otherSourceToBuiltPath,
  overviewSourceToBuiltPath,
  parseBuiltPage,
  parseSourceExample,
} from "./paths.js";

function exampleKey(parsed) {
  const scope = parsed.major === undefined ? "" : `v${parsed.major}/`;
  return `${scope}${parsed.policy}/${parsed.name}`;
}

// builtPages/sourceExamples: example-page paths, as before. overviewSources and
// otherSources: source pages that use {% policy_yaml %}; each must have its
// built page on disk under root. A source page whose built page exists but
// whose tab-group count differs is NOT a precondition failure; that mismatch
// is a gating finding during the run.
export function checkPreconditions(
  builtPages,
  sourceExamples,
  overviewSources = [],
  otherSources = [],
  root = process.cwd(),
) {
  if (builtPages.length === 0) {
    return {
      ok: false,
      message:
        "No built mesh policy example pages found. Build the site for " +
        "production first (dist/mesh/policies/*/examples/*/index.html or " +
        "dist/mesh/v2/policies/*/examples/*/index.html).",
    };
  }

  const builtKeys = new Set(builtPages.map((page) => exampleKey(parseBuiltPage(page))));

  const missing = sourceExamples.filter(
    (source) => !builtKeys.has(exampleKey(parseSourceExample(source))),
  );

  if (missing.length > 0) {
    return {
      ok: false,
      message:
        `Built ${builtPages.length} mesh policy example pages but found ` +
        `${sourceExamples.length} source examples. No built page for: ` +
        `${missing.join(", ")}.`,
    };
  }

  const meshPages = [
    ...overviewSources.map((source) => ({
      source,
      builtPath: overviewSourceToBuiltPath(source),
    })),
    ...otherSources.map((source) => ({
      source,
      builtPath: otherSourceToBuiltPath(source),
    })),
  ];
  const missingPages = meshPages.filter(
    (page) => !fs.existsSync(path.join(root, page.builtPath)),
  );

  if (missingPages.length > 0) {
    return {
      ok: false,
      message:
        `No built page for source page(s): ` +
        `${missingPages.map((page) => page.source).join(", ")}. ` +
        `Build the site for production first.`,
    };
  }

  return { ok: true };
}
