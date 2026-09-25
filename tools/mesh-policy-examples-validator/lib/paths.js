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
const OVERVIEW_SOURCE_PATTERN =
  /^app\/_mesh_policies\/(?:v(\d+)\/)?([^/]+)\/index\.md$/;
const OTHER_SOURCE_PATTERN =
  /^app\/mesh\/(?:v(\d+)\/)?([^/]+)\.md$/;

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

export function parseOverviewSource(sourcePath) {
  const match = sourcePath.match(OVERVIEW_SOURCE_PATTERN);
  if (!match) return undefined;
  return {
    major: match[1] === undefined ? undefined : Number(match[1]),
    policy: match[2],
  };
}

export function parseOtherSource(sourcePath) {
  const match = sourcePath.match(OTHER_SOURCE_PATTERN);
  if (!match) return undefined;
  return {
    major: match[1] === undefined ? undefined : Number(match[1]),
    slug: match[2],
  };
}

export function overviewSourceToBuiltPath(sourcePath) {
  const parsed = parseOverviewSource(sourcePath);
  if (!parsed) {
    throw new Error(`Not a mesh policy overview page path: ${sourcePath}`);
  }
  const { major, policy } = parsed;
  return `dist/mesh/${major === undefined ? "" : `v${major}/`}policies/${policy}/index.html`;
}

export function otherSourceToBuiltPath(sourcePath) {
  const parsed = parseOtherSource(sourcePath);
  if (!parsed) {
    throw new Error(`Not a mesh page source path: ${sourcePath}`);
  }
  const { major, slug } = parsed;
  return `dist/mesh/${major === undefined ? "" : `v${major}/`}${slug}/index.html`;
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
