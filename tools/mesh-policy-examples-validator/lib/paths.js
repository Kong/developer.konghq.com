import fs from "fs";
import path from "path";

const BUILT_PAGE_PATTERN =
  /dist\/mesh\/(v2\/)?policies\/([^/]+)\/examples\/([^/]+)\/index\.html$/;

export function builtPageToSourcePath(root, builtPagePath) {
  const match = builtPagePath.match(BUILT_PAGE_PATTERN);
  if (!match) {
    throw new Error(`Not a mesh policy example page path: ${builtPagePath}`);
  }
  const [, versionSegment, policy, name] = match;

  for (const ext of ["yaml", "yml"]) {
    const candidate = path.join(
      root,
      "app/_mesh_policies",
      ...(versionSegment ? [versionSegment.replace(/\/$/, "")] : []),
      policy,
      "examples",
      `${name}.${ext}`,
    );
    if (fs.existsSync(candidate)) return candidate;
  }

  return path.join(
    root,
    "app/_mesh_policies",
    ...(versionSegment ? [versionSegment.replace(/\/$/, "")] : []),
    policy,
    "examples",
    `${name}.yaml`,
  );
}
