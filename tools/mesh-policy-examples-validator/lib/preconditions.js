const SOURCE_EXAMPLE_PATTERN =
  /app\/_mesh_policies\/([^/]+)\/examples\/([^/]+)\.ya?ml$/;
const BUILT_PAGE_PATTERN =
  /dist\/mesh\/policies\/([^/]+)\/examples\/([^/]+)\/index\.html$/;

function exampleKey(policy, name) {
  return `${policy}/${name}`;
}

export function checkPreconditions(builtPages, sourceExamples) {
  if (builtPages.length === 0) {
    return {
      ok: false,
      message:
        "No built mesh policy example pages found. Build the site for " +
        "production first (dist/mesh/policies/*/examples/*/index.html).",
    };
  }

  const builtKeys = new Set(
    builtPages.map((page) => {
      const match = page.match(BUILT_PAGE_PATTERN);
      return exampleKey(match[1], match[2]);
    }),
  );

  const missing = sourceExamples.filter((source) => {
    const match = source.match(SOURCE_EXAMPLE_PATTERN);
    return !builtKeys.has(exampleKey(match[1], match[2]));
  });

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
