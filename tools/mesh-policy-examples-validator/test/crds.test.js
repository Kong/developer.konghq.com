import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import { loadCrds } from "../lib/crds.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");
const CRDS_DIR = path.join(ROOT, "app/assets/mesh/2.14.x/raw/crds");

// The distinct config.type values across all 58 mesh policy example source files.
const EXAMPLE_KINDS = [
  "ExternalService",
  "MeshAccessLog",
  "MeshCircuitBreaker",
  "MeshFaultInjection",
  "MeshGlobalRateLimit",
  "MeshHTTPRoute",
  "MeshHealthCheck",
  "MeshIdentity",
  "MeshLoadBalancingStrategy",
  "MeshMetric",
  "MeshOPA",
  "MeshPassthrough",
  "MeshProxyPatch",
  "MeshRateLimit",
  "MeshRetry",
  "MeshTCPRoute",
  "MeshTLS",
  "MeshTimeout",
  "MeshTrace",
  "MeshTrafficPermission",
  "MeshTrust",
];

test("every example kind resolves against the real 2.14 CRD directory", () => {
  const crds = loadCrds(CRDS_DIR);
  for (const kind of EXAMPLE_KINDS) {
    assert.ok(crds.has(kind), `expected a CRD for kind ${kind}`);
  }
});

test("MeshTLS and MeshRetry resolve, where naive pluralisation would fail", () => {
  const crds = loadCrds(CRDS_DIR);
  assert.ok(crds.has("MeshTLS"));
  assert.ok(crds.has("MeshRetry"));
});
