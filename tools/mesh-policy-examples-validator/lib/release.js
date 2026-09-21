import fs from "fs";
import path from "path";
import YAML from "yaml";

export class MissingCrdDirectoryError extends Error {
  constructor(release, crdsDir) {
    super(`No vendored CRD schemas for mesh release "${release}" at ${crdsDir}`);
    this.name = "MissingCrdDirectoryError";
    this.release = release;
    this.crdsDir = crdsDir;
  }
}

// root: repo root. major: the mesh major to resolve (2, 3, ...). override: an
// explicit release string (e.g. "2.10") that pins this major when it belongs
// to it; releases of other majors keep their default resolution.
export function resolveRelease(root, major, override) {
  const productsPath = path.join(root, "app/_data/products/mesh.yml");
  const releases = YAML.parse(
    fs.readFileSync(productsPath, "utf-8"),
  ).releases.filter((entry) => releaseMajor(entry.release) === major);

  let release;
  if (override && releaseMajor(override) === major) {
    release = String(override);
  } else {
    release = biggestRelease(releases);
    if (!release) {
      throw new Error(`No release for mesh major ${major} in ${productsPath}`);
    }
  }

  const entry = releases.find((candidate) => candidate.release === release) || {};
  const dir = entry.label || `${release}.x`;
  const crdsDir = path.join(root, "app/assets/mesh", dir, "raw", "crds");
  if (!fs.existsSync(crdsDir)) {
    throw new MissingCrdDirectoryError(release, crdsDir);
  }

  return { release, crdsDir };
}

function releaseMajor(release) {
  return Number(String(release).split(".")[0]);
}

function biggestRelease(releases) {
  return releases
    .map((entry) => String(entry.release))
    .sort((a, b) => {
      const [aMajor, aMinor] = a.split(".").map(Number);
      const [bMajor, bMinor] = b.split(".").map(Number);
      return bMajor - aMajor || bMinor - aMinor;
    })
    .at(0);
}
