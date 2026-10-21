import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

import {
  buildKubernetesResourceCommand,
  buildKubernetesResourcePropertyCommand,
  buildKubernetesWaitForCommand,
  checkKubernetesResourceCondition,
  compareKubernetesResourceProperty,
} from "../instructions/kubernetes-commands.js";

// The kubernetes-* validation builders mirror the commands the how-to
// snippets render (app/_includes/how-tos/validations/kubernetes-*): a reader
// following the page and the runner must agree on what runs. Every built
// command executes through `bash -c` (docker-helper.js executeCommand), so
// every interpolated config value is single-quoted with embedded quotes
// escaped (' -> '\''), the same rule container-request.js applies.

// Expected commands are written heredoc-style, one flag per line, then
// joined into the single-line command the builders emit.
const command = (heredoc) =>
  heredoc
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .join(" ");

// A builder that emits unparseable shell is broken no matter how right the
// strings look, so every test also runs `bash -n` on the built command
// (parse without execute).
function assertValidBash(built) {
  const result = spawnSync("bash", ["-n"], { input: built });
  assert.equal(
    result.status,
    0,
    `bash -n rejected the built command:\n${built}\n${result.stderr}`,
  );
}

// buildKubernetesResourceCommand mirrors the kubernetes-resource snippet:
// `kubectl get [-n ns] <kind> <name> -o=jsonpath='{.status.conditions[?(@.type=="<type>")]}'`.
// The runner omits the snippet's `| jq` display pipe and parses the jsonpath
// output in-process instead. The kind is downcased like the snippet does, the
// namespace defaults to `kong`, and the condition type defaults to `Programmed`
// (the site-level app/_data/how-tos/config.yaml spells that key `type`, the
// snippet `conditionType`).

test("buildKubernetesResourceCommand emits the jsonpath get for a minimal config", () => {
  const built = buildKubernetesResourceCommand({
    kind: "KonnectGatewayControlPlane",
    name: "gateway-control-plane",
  });

  assert.equal(
    built,
    command(`
      kubectl get -n 'kong' 'konnectgatewaycontrolplane' 'gateway-control-plane'
      -o=jsonpath='{.status.conditions[?(@.type=="Programmed")]}'
    `),
  );
  assertValidBash(built);
});

test("buildKubernetesResourceCommand includes an explicit namespace", () => {
  const built = buildKubernetesResourceCommand({
    kind: "DataPlane",
    name: "dataplane-example",
    namespace: "kong-system",
  });

  assert.equal(
    built,
    command(`
      kubectl get -n 'kong-system' 'dataplane' 'dataplane-example'
      -o=jsonpath='{.status.conditions[?(@.type=="Programmed")]}'
    `),
  );
  assertValidBash(built);
});

test("buildKubernetesResourceCommand prefers conditionType over the site-level type spelling", () => {
  const built = buildKubernetesResourceCommand({
    kind: "DataPlane",
    name: "dataplane-example",
    conditionType: "Ready",
    type: "Programmed",
  });

  assert.equal(
    built,
    command(`
      kubectl get -n 'kong' 'dataplane' 'dataplane-example'
      -o=jsonpath='{.status.conditions[?(@.type=="Ready")]}'
    `),
  );
  assertValidBash(built);
});

test("buildKubernetesResourceCommand falls back to the site-level type spelling", () => {
  const built = buildKubernetesResourceCommand({
    kind: "DataPlane",
    name: "dataplane-example",
    type: "Ready",
  });

  assert.equal(
    built,
    command(`
      kubectl get -n 'kong' 'dataplane' 'dataplane-example'
      -o=jsonpath='{.status.conditions[?(@.type=="Ready")]}'
    `),
  );
  assertValidBash(built);
});

// buildKubernetesResourcePropertyCommand mirrors the
// kubernetes-resource-property snippet:
// `kubectl get -o yaml -n <ns> <kind> <name> | yq '<path>'`, or, with
// name_selector, a `NAME=$(kubectl get -o yaml -n <ns> <kind> | yq '<selector>')`
// preamble whose `$NAME` the get command references on the next line. The
// snippet strips path and name_selector (`| strip`); how-tos write them as
// YAML block scalars, so they arrive with a trailing newline the builders
// must trim.

test("buildKubernetesResourcePropertyCommand emits the get | yq shape for a named resource", () => {
  const built = buildKubernetesResourcePropertyCommand({
    kind: "pod",
    name: "my-pod",
    path: ".spec.containers[].image",
  });

  assert.equal(
    built,
    `kubectl get -o yaml -n 'kong' 'pod' 'my-pod' | yq '.spec.containers[].image'`,
  );
  assertValidBash(built);
});

test("buildKubernetesResourcePropertyCommand includes an explicit namespace", () => {
  const built = buildKubernetesResourcePropertyCommand({
    kind: "pod",
    name: "my-pod",
    namespace: "kong-system",
    path: ".spec.containers[].image",
  });

  assert.equal(
    built,
    `kubectl get -o yaml -n 'kong-system' 'pod' 'my-pod' | yq '.spec.containers[].image'`,
  );
  assertValidBash(built);
});

test("buildKubernetesResourcePropertyCommand prepends the name_selector resolution and references $NAME", () => {
  // Ground truth: the set-dataplane-image on-prem instruction file carries
  // exactly this config (input/instructions/operator/dataplanes/how-to/
  // set-dataplane-image/on-prem/operator.yaml), with path and name_selector
  // as YAML block scalars (trailing newline included).
  const built = buildKubernetesResourcePropertyCommand({
    kind: "pod",
    name_selector:
      ".items[].metadata.name | select(contains(\"dataplane-example\"))\n",
    path: ".spec.containers[] | select(.name == \"proxy\") | .image\n",
    expected: "kong/kong-gateway:3.10",
  });

  assert.equal(
    built,
    [
      `NAME=$(kubectl get -o yaml -n 'kong' 'pod' | yq '.items[].metadata.name | select(contains("dataplane-example"))')`,
      `kubectl get -o yaml -n 'kong' 'pod' $NAME | yq '.spec.containers[] | select(.name == "proxy") | .image'`,
    ].join("\n"),
  );
  assertValidBash(built);
});

test("buildKubernetesResourcePropertyCommand single-quote-escapes path and selector values containing quotes", () => {
  const built = buildKubernetesResourcePropertyCommand({
    kind: "pod",
    name_selector: ".items[].metadata.name | select(contains(\"dp's\"))",
    path: ".spec.containers[] | select(.name == \"it's\") | .image",
  });

  assert.equal(
    built,
    [
      `NAME=$(kubectl get -o yaml -n 'kong' 'pod' | yq '.items[].metadata.name | select(contains("dp'\\''s"))')`,
      `kubectl get -o yaml -n 'kong' 'pod' $NAME | yq '.spec.containers[] | select(.name == "it'\\''s") | .image'`,
    ].join("\n"),
  );
  // `bash -n` proves the escaping survives the shell parse; yq then receives
  // the selector and path verbatim, quotes intact.
  assertValidBash(built);
});

// buildKubernetesWaitForCommand mirrors the kubernetes-wait-for snippet:
// `kubectl wait -n <ns> --timeout=<t> <kind>/<resource>
// --for='jsonpath={<field>[?(@.type=="<type>")].status}=<expected>'`.
// The `=value` suffix is the strict-comparison form: kubectl splits --for on
// single `=` only (`==` inside the jsonpath filter survives), and a present
// value puts the wait on the strict compareResults path instead of the
// matchAnyValue path that succeeds on missing fields.

test("buildKubernetesWaitForCommand defaults an httproute to the Programmed condition", () => {
  // Ground truth: the kic-proxy-http how-to carries exactly this config.
  const built = buildKubernetesWaitForCommand({
    kind: "httproute",
    resource: "echo",
  });

  assert.equal(
    built,
    command(`
      kubectl wait -n 'kong' --timeout='30s' 'httproute/echo'
      --for='jsonpath={.status.parents[?(@.parentRef.name=="kong")].conditions[?(@.type=="Programmed")].status}=True'
    `),
  );
  assertValidBash(built);
});

test("buildKubernetesWaitForCommand defaults a non-httproute to the Accepted condition", () => {
  const built = buildKubernetesWaitForCommand({
    kind: "Gateway",
    resource: "kong",
  });

  assert.equal(
    built,
    command(`
      kubectl wait -n 'kong' --timeout='30s' 'gateway/kong'
      --for='jsonpath={.status.parents[?(@.parentRef.name=="kong")].conditions[?(@.type=="Accepted")].status}=True'
    `),
  );
  assertValidBash(built);
});

test("buildKubernetesWaitForCommand honors explicit status_field, status_type, expected, timeout, and namespace", () => {
  const built = buildKubernetesWaitForCommand({
    kind: "Gateway",
    resource: "kong",
    namespace: "custom-ns",
    status_field: ".status.conditions",
    status_type: "Programmed",
    expected: "False",
    timeout: "60s",
  });

  assert.equal(
    built,
    command(`
      kubectl wait -n 'custom-ns' --timeout='60s' 'gateway/kong'
      --for='jsonpath={.status.conditions[?(@.type=="Programmed")].status}=False'
    `),
  );
  assertValidBash(built);
});

// checkKubernetesResourceCondition parses the jsonpath output of the
// kubernetes-resource command and decides pass/fail: the condition must
// exist with the expected status, plus the configured observedGeneration
// and reason when present. It takes the same emitted config the builder
// takes, so it honors both spellings the site defaults and the snippet use
// (`conditionType` or `type`, `status` as the expected status) and applies
// the same defaults (Programmed, "True"). The failure message must name the
// resource, the condition type, and the observed status.

const conditionConfig = { kind: "DataPlane", name: "dataplane-example" };

test("checkKubernetesResourceCondition passes a reconciled condition with all defaults", () => {
  const check = checkKubernetesResourceCondition(
    conditionConfig,
    `{"lastTransitionTime":"2026-10-21T00:00:00Z","observedGeneration":1,"reason":"Programmed","status":"True","type":"Programmed"}`,
  );

  assert.equal(check.pass, true);
});

test("checkKubernetesResourceCondition passes configured observedGeneration and reason when they match", () => {
  const check = checkKubernetesResourceCondition(
    { ...conditionConfig, observedGeneration: 2, reason: "Programmed" },
    `{"observedGeneration":2,"reason":"Programmed","status":"True","type":"Programmed"}`,
  );

  assert.equal(check.pass, true);
});

test("checkKubernetesResourceCondition fails a non-True status, naming resource, type, and observed status", () => {
  const check = checkKubernetesResourceCondition(
    { ...conditionConfig, status: "True" },
    `{"observedGeneration":1,"reason":"Programmed","status":"False","type":"Programmed"}`,
  );

  assert.equal(check.pass, false);
  assert.match(check.message, /DataPlane dataplane-example/);
  assert.match(check.message, /Programmed/);
  assert.match(check.message, /"False"/);
});

test("checkKubernetesResourceCondition fails a missing condition, naming the conditionType spelling", () => {
  const check = checkKubernetesResourceCondition(
    { ...conditionConfig, conditionType: "Ready" },
    "",
  );

  assert.equal(check.pass, false);
  assert.match(check.message, /DataPlane dataplane-example/);
  assert.match(check.message, /Ready/);
});

test("checkKubernetesResourceCondition fails unparseable output", () => {
  const check = checkKubernetesResourceCondition(
    conditionConfig,
    "Error from server (NotFound): dataplanes.gateway-operator.konghq.com not found",
  );

  assert.equal(check.pass, false);
});

test("checkKubernetesResourceCondition fails an observedGeneration mismatch", () => {
  const check = checkKubernetesResourceCondition(
    { ...conditionConfig, observedGeneration: 2 },
    `{"observedGeneration":1,"reason":"Programmed","status":"True","type":"Programmed"}`,
  );

  assert.equal(check.pass, false);
  assert.match(check.message, /observedGeneration/);
});

test("checkKubernetesResourceCondition fails a reason mismatch", () => {
  const check = checkKubernetesResourceCondition(
    { ...conditionConfig, reason: "Programmed" },
    `{"observedGeneration":1,"reason":"Pending","status":"True","type":"Programmed"}`,
  );

  assert.equal(check.pass, false);
  assert.match(check.message, /reason/);
});

// compareKubernetesResourceProperty decides pass/fail for the
// kubernetes-resource-property command's yq output: the trimmed output must
// equal the expected value. It takes the same emitted config the builder
// takes. Any non-matching output fails: a name_selector that matched no
// resource resolves an empty $NAME, the get returns the whole list, and the
// yq path evaluates to null on it.

test("compareKubernetesResourceProperty passes a matching value", () => {
  const check = compareKubernetesResourceProperty(
    {
      expected: "kong/kong-gateway:3.10",
      path: ".spec.containers[] | select(.name == \"proxy\") | .image",
    },
    "kong/kong-gateway:3.10\n",
  );

  assert.equal(check.pass, true);
});

test("compareKubernetesResourceProperty trims a block-scalar expected value", () => {
  // A writer copying the `|` block-scalar habit from path/name_selector to
  // expected would otherwise bake the trailing newline into the comparison
  // target and never pass.
  const check = compareKubernetesResourceProperty(
    { expected: "kong/kong-gateway:3.10\n" },
    "kong/kong-gateway:3.10\n",
  );

  assert.equal(check.pass, true);
});

test("compareKubernetesResourceProperty coerces a scalar expected value to string", () => {
  const check = compareKubernetesResourceProperty(
    { expected: 3 },
    "3\n",
  );

  assert.equal(check.pass, true);
});

test("compareKubernetesResourceProperty fails a mismatch, showing expected and actual", () => {
  const check = compareKubernetesResourceProperty(
    { expected: "kong/kong-gateway:3.10" },
    "kong/kong-gateway:3.11\n",
  );

  assert.equal(check.pass, false);
  assert.match(check.message, /kong\/kong-gateway:3\.10/);
  assert.match(check.message, /kong\/kong-gateway:3\.11/);
});

test("compareKubernetesResourceProperty fails an empty name_selector result", () => {
  const check = compareKubernetesResourceProperty(
    {
      kind: "pod",
      expected: "kong/kong-gateway:3.10",
      name_selector: ".items[].metadata.name | select(contains(\"dataplane-example\"))",
    },
    "",
  );

  assert.equal(check.pass, false);
  assert.match(check.message, /kong\/kong-gateway:3\.10/);
  assert.match(check.message, /name_selector/);
});
