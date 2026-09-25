import test from "node:test";
import assert from "node:assert/strict";
import path from "path";
import { fileURLToPath } from "url";
import {
  builtPageToSourcePath,
  otherSourceToBuiltPath,
  overviewSourceToBuiltPath,
  parseOtherSource,
  parseOverviewSource,
} from "../lib/paths.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../..");
const FIXTURE_ROOT = path.resolve(__dirname, "fixtures/paths-root");

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

test("maps a v2 built page to a .yml source (external-services)", () => {
  const source = builtPageToSourcePath(
    ROOT,
    "dist/mesh/v2/policies/external-services/examples/zone-egress/index.html",
  );
  assert.equal(
    source,
    path.join(
      ROOT,
      "app/_mesh_policies/v2/external-services/examples/zone-egress.yml",
    ),
  );
});

test("maps a v2 built page to the v2 source tree", () => {
  const source = builtPageToSourcePath(
    FIXTURE_ROOT,
    "dist/mesh/v2/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  );
  assert.equal(
    source,
    path.join(
      FIXTURE_ROOT,
      "app/_mesh_policies/v2/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
    ),
  );
});

test("maps a v2 built page to a .yml source (external-services)", () => {
  const source = builtPageToSourcePath(
    FIXTURE_ROOT,
    "dist/mesh/v2/policies/external-services/examples/zone-egress/index.html",
  );
  assert.equal(
    source,
    path.join(
      FIXTURE_ROOT,
      "app/_mesh_policies/v2/external-services/examples/zone-egress.yml",
    ),
  );
});

test("maps an unversioned built page against the fixture root", () => {
  const source = builtPageToSourcePath(
    FIXTURE_ROOT,
    "dist/mesh/policies/meshcircuitbreaker/examples/basic-circuit-breaker/index.html",
  );
  assert.equal(
    source,
    path.join(
      FIXTURE_ROOT,
      "app/_mesh_policies/meshcircuitbreaker/examples/basic-circuit-breaker.yaml",
    ),
  );
});

test("parses an unversioned overview source page", () => {
  assert.deepEqual(parseOverviewSource("app/_mesh_policies/meshtimeout/index.md"), {
    major: undefined,
    policy: "meshtimeout",
  });
});

test("parses a v2 overview source page", () => {
  assert.deepEqual(
    parseOverviewSource("app/_mesh_policies/v2/meshmetric/index.md"),
    { major: 2, policy: "meshmetric" },
  );
});

test("a non-overview path does not parse as an overview source", () => {
  assert.equal(
    parseOverviewSource("app/_mesh_policies/meshtimeout/examples/basic.yaml"),
    undefined,
  );
});

test("maps an unversioned overview source to its built page", () => {
  assert.equal(
    overviewSourceToBuiltPath("app/_mesh_policies/meshtimeout/index.md"),
    "dist/mesh/policies/meshtimeout/index.html",
  );
});

test("maps a v2 overview source to its built page", () => {
  assert.equal(
    overviewSourceToBuiltPath("app/_mesh_policies/v2/meshmetric/index.md"),
    "dist/mesh/v2/policies/meshmetric/index.html",
  );
});

test("mapping a non-overview path to a built page fails loudly", () => {
  assert.throws(
    () => overviewSourceToBuiltPath("app/mesh/meshservice.md"),
    /Not a mesh policy overview page path/,
  );
});

test("parses an unversioned other mesh source page", () => {
  assert.deepEqual(parseOtherSource("app/mesh/meshservice.md"), {
    major: undefined,
    slug: "meshservice",
  });
});

test("parses a v2 other mesh source page", () => {
  assert.deepEqual(parseOtherSource("app/mesh/v2/hostnamegenerator.md"), {
    major: 2,
    slug: "hostnamegenerator",
  });
});

test("a non-page path does not parse as an other mesh source", () => {
  assert.equal(parseOtherSource("app/mesh/v2/hostnamegenerator/examples/x.yaml"), undefined);
});

test("maps an unversioned other mesh source to its built page", () => {
  assert.equal(
    otherSourceToBuiltPath("app/mesh/meshservice.md"),
    "dist/mesh/meshservice/index.html",
  );
});

test("maps a v2 other mesh source to its built page", () => {
  assert.equal(
    otherSourceToBuiltPath("app/mesh/v2/hostnamegenerator.md"),
    "dist/mesh/v2/hostnamegenerator/index.html",
  );
});

test("mapping a non-page path to a built page fails loudly", () => {
  assert.throws(
    () => otherSourceToBuiltPath("app/_mesh_policies/meshtimeout/index.md"),
    /Not a mesh page source path/,
  );
});
