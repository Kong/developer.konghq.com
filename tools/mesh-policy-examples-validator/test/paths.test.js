import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import { builtPageToSourcePath } from "../lib/paths.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");

test("maps a built page to a .yaml source", () => {
  const source = builtPageToSourcePath(
    ROOT,
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  );
  assert.equal(
    source,
    path.join(
      ROOT,
      "app/_mesh_policies/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
    ),
  );
});

test("maps a built page to a .yml source (external-services)", () => {
  const source = builtPageToSourcePath(
    ROOT,
    "dist/mesh/policies/external-services/examples/zone-egress/index.html",
  );
  assert.equal(
    source,
    path.join(
      ROOT,
      "app/_mesh_policies/external-services/examples/zone-egress.yml",
    ),
  );
});
