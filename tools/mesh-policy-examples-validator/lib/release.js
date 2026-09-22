import fs from "fs";
import path from "path";
import YAML from "yaml";

export class MissingCrdDirectoryError extends Error {
  constructor(release, crdsDir) {
    super(
      `No vendored CRD schemas for mesh release "${release}" at ${crdsDir}`,
    );
    this.name = "MissingCrdDirectoryError";
    this.release = release;
    this.crdsDir = crdsDir;
  }
}

// root: repo root. override: an explicit release string (e.g. "2.10"), bypassing the "latest" lookup.
export function resolveRelease(root, override) {
  const productsPath = path.join(root, "app/_data/products/mesh.yml");
  const data = YAML.parse(fs.readFileSync(productsPath, "utf-8"));
  const releases = data.releases || [];

  let release;
  if (override) {
    release = String(override);
  } else {
    const latest = releases.find((entry) => entry.latest === true);
    if (!latest) {
      throw new Error(`No release marked "latest: true" in ${productsPath}`);
    }
    release = latest.release;
  }

  const crdsDir = path.join(
    root,
    "app/assets/mesh",
    `${release}.x`,
    "raw",
    "crds",
  );
  if (!fs.existsSync(crdsDir)) {
    throw new MissingCrdDirectoryError(release, crdsDir);
  }

  return { release, crdsDir };
}
