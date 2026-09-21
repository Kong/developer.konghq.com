import { parseBuiltPage, parseSourceExample } from "./paths.js";

function exampleKey(parsed) {
  const scope = parsed.major === undefined ? "" : `v${parsed.major}/`;
  return `${scope}${parsed.policy}/${parsed.name}`;
}

export function checkPreconditions(builtPages, sourceExamples) {
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

  return { ok: true };
}
