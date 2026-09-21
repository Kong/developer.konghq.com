import fs from "fs";
import path from "path";

// Single source of truth for the built-page and source-example path shapes.
// The optional `v<N>/` segment names a previous-major tree; its captured
// number is the mesh major (2 for `v2/`). No segment means the unversioned
// latest tree.
const BUILT_PAGE_PATTERN =
  /^dist\/mesh\/(?:v(\d+)\/)?policies\/([^/]+)\/examples\/([^/]+)\/index\.html$/;
const SOURCE_EXAMPLE_PATTERN =
  /^app\/_mesh_policies\/(?:v(\d+)\/)?([^/]+)\/examples\/([^/]+)\.ya?ml$/;

function parsePath(pattern, examplePath) {
  const match = examplePath.match(pattern);
  if (!match) return undefined;
  return {
    major: match[1] === undefined ? undefined : Number(match[1]),
    policy: match[2],
    name: match[3],
  };
}

export function parseBuiltPage(pagePath) {
  return parsePath(BUILT_PAGE_PATTERN, pagePath);
}

export function parseSourceExample(sourcePath) {
  return parsePath(SOURCE_EXAMPLE_PATTERN, sourcePath);
}

export function builtPageToSourcePath(root, builtPagePath) {
  const parsed = parseBuiltPage(builtPagePath);
  if (!parsed) {
    throw new Error(`Not a mesh policy example page path: ${builtPagePath}`);
  }
  const { major, policy, name } = parsed;
  const versionParts = major === undefined ? [] : [`v${major}`];

  for (const ext of ["yaml", "yml"]) {
    const candidate = path.join(
      root,
      "app/_mesh_policies",
      ...versionParts,
      policy,
      "examples",
      `${name}.${ext}`,
    );
    if (fs.existsSync(candidate)) return candidate;
  }

  return path.join(
    root,
    "app/_mesh_policies",
    ...versionParts,
    policy,
    "examples",
    `${name}.yaml`,
  );
}
