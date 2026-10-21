// Pure, container-free helpers for the three kubernetes-* validation types
// (kubernetes-resource, kubernetes-resource-property, kubernetes-wait-for).
// Each builder mirrors the command its how-to snippet renders
// (app/_includes/how-tos/validations/kubernetes-*/snippet.md): the rendered
// command is the documented contract, so a reader following the page and the
// runner agree on what runs. The comparisons decide pass/fail for the two
// assertion types; kubernetes-wait-for needs none, because kubectl's own
// exit code (governed by --timeout) decides it.
//
// Scope notes:
// - kubernetes-resource-property compares single scalar yq results. The
//   family's use today is single values (an image, a resolved name);
//   multi-value or multi-document yq output is out of scope and fails the
//   comparison loudly rather than being interpreted.
// - kubernetes-wait-for uses the strict `=value` comparison form
//   (`--for='jsonpath={...}.status}=True'`). kubectl splits --for on single
//   `=` only (the `==` inside the jsonpath filter survives), and a present
//   value puts the wait on the strict compareResults path instead of the
//   matchAnyValue path that succeeds on missing fields. The rendered
//   snippet carries a stray space inside the closing brace (`.status }`);
//   the builder omits it, matching kubectl's own documented example.
// - The emitted config merges the site-level defaults from
//   app/_data/how-tos/config.yaml into the how-to's YAML, so the
//   normalizers accept both spellings the site config and the snippets use
//   (`conditionType` or `type`, `observedGeneration` or the snippet's
//   `generation` display key) and re-apply the render-time defaults the
//   snippets bake in (namespace `kong`, `Programmed`/`Accepted` condition
//   types with the httproute quirk, expected `True`, wait timeout `30s`).
//
// This module is unit-tested in test/kubernetes-commands.test.js; the
// validations.js hooks stay thin (classification + delegation to these
// helpers) and un-unit-tested per the established seam (see
// container-request.js).

import { shellQuote } from "./container-request.js";

const DEFAULT_NAMESPACE = "kong";
const DEFAULT_WAIT_STATUS_FIELD =
  '.status.parents[?(@.parentRef.name=="kong")].conditions';

// The snippets downcase the kind ({{ kind | downcase }}), so kubectl receives
// the lowercase resource name the page renders.
function downcaseKind(kind) {
  return String(kind).toLowerCase();
}

// kubernetes-resource: `kubectl get [-n ns] <kind> <name>
// -o=jsonpath='{.status.conditions[?(@.type=="<type>")]}'`. The snippet's
// trailing `| jq` is display-only; the runner parses the jsonpath output
// in-process (checkKubernetesResourceCondition) instead.
export function buildKubernetesResourceCommand(config) {
  const normalized = normalizeKubernetesResourceConfig(config);
  const jsonpath = `{.status.conditions[?(@.type=="${normalized.conditionType}")]}`;

  return [
    "kubectl",
    "get",
    `-n ${shellQuote(normalized.namespace)}`,
    shellQuote(downcaseKind(normalized.kind)),
    shellQuote(normalized.name),
    `-o=jsonpath=${shellQuote(jsonpath)}`,
  ].join(" ");
}

// kubernetes-resource-property: `kubectl get -o yaml -n <ns> <kind> <name> |
// yq '<path>'`, or, with name_selector, a
// `NAME=$(kubectl get -o yaml -n <ns> <kind> | yq '<selector>')` preamble
// whose `$NAME` the get command references on the next line. $NAME stays
// unquoted (it must expand, and resource names cannot contain whitespace).
export function buildKubernetesResourcePropertyCommand(config) {
  const normalized = normalizeKubernetesResourcePropertyConfig(config);
  const namespace = shellQuote(normalized.namespace);
  const kind = shellQuote(downcaseKind(normalized.kind));
  const listCommand = `kubectl get -o yaml -n ${namespace} ${kind}`;
  const target = normalized.nameSelector ? "$NAME" : shellQuote(normalized.name);
  const getCommand = `${listCommand} ${target} | yq ${shellQuote(normalized.path)}`;

  if (!normalized.nameSelector) {
    return getCommand;
  }

  return [
    `NAME=$(${listCommand} | yq ${shellQuote(normalized.nameSelector)})`,
    getCommand,
  ].join("\n");
}

// kubernetes-wait-for: `kubectl wait -n <ns> --timeout=<t> <kind>/<resource>
// --for='jsonpath={<field>[?(@.type=="<type>")].status}=<expected>'`.
export function buildKubernetesWaitForCommand(config) {
  const normalized = normalizeKubernetesWaitForConfig(config);
  const condition = `jsonpath={${normalized.statusField}[?(@.type=="${normalized.statusType}")].status}=${normalized.expected}`;

  return [
    "kubectl",
    "wait",
    `-n ${shellQuote(normalized.namespace)}`,
    `--timeout=${shellQuote(normalized.timeout)}`,
    shellQuote(`${downcaseKind(normalized.kind)}/${normalized.resource}`),
    `--for=${shellQuote(condition)}`,
  ].join(" ");
}

// Defaults: the site-level config spells the condition type `type` and the
// expected status `status`; the snippet reads `conditionType`. observedGeneration
// is asserted only when the config sets it (either spelling); so is reason.
export function normalizeKubernetesResourceConfig(config) {
  return {
    kind: config.kind,
    name: config.name,
    namespace: config.namespace ?? DEFAULT_NAMESPACE,
    conditionType: config.conditionType ?? config.type ?? "Programmed",
    expectedStatus: config.status ?? "True",
    observedGeneration: config.observedGeneration ?? config.generation,
    reason: config.reason,
  };
}

// Defaults: namespace `kong`. path and name_selector arrive from YAML block
// scalars with a trailing newline; the snippet strips them (`| strip`), so
// the normalizer trims.
export function normalizeKubernetesResourcePropertyConfig(config) {
  return {
    kind: config.kind,
    name: config.name,
    nameSelector: config.name_selector?.trim(),
    path: config.path?.trim(),
    namespace: config.namespace ?? DEFAULT_NAMESPACE,
    expected: config.expected,
  };
}

// Defaults: namespace `kong`, status_field `.status.parents[?(@.parentRef.
// name=="kong")].conditions`, status_type `Accepted` (except `httproute`,
// which defaults to `Programmed`), expected `True`, timeout `30s`. The
// httproute check compares the raw kind, exactly like the snippet's
// `{% if kind == "httproute" %}`.
export function normalizeKubernetesWaitForConfig(config) {
  return {
    kind: config.kind,
    resource: config.resource,
    namespace: config.namespace ?? DEFAULT_NAMESPACE,
    statusField: config.status_field ?? DEFAULT_WAIT_STATUS_FIELD,
    statusType:
      config.status_type ??
      (config.kind === "httproute" ? "Programmed" : "Accepted"),
    expected: config.expected ?? "True",
    timeout: config.timeout ?? "30s",
  };
}

// Pass only when the condition exists with the expected status (plus the
// configured observedGeneration and reason when present). Empty output (the
// condition is missing) or unparseable output (kubectl error text, multiple
// concatenated matches) fails the attempt and consumes a retry.
export function checkKubernetesResourceCondition(config, output) {
  const normalized = normalizeKubernetesResourceConfig(config);
  const resource = `${normalized.kind} ${normalized.name}`;
  const expectedLine = `Expected: ${resource} to have a ${normalized.conditionType} condition with status "${normalized.expectedStatus}"`;

  const trimmed = (output ?? "").trim();
  if (trimmed === "") {
    return {
      pass: false,
      message: `${expectedLine}, got: no ${normalized.conditionType} condition (empty output, the resource may not be reconciled yet).`,
    };
  }

  let condition;
  try {
    condition = JSON.parse(trimmed);
  } catch {
    return {
      pass: false,
      message: `${expectedLine}, got: unparseable output: ${JSON.stringify(trimmed)}.`,
    };
  }

  if (condition?.status !== normalized.expectedStatus) {
    return {
      pass: false,
      message: `${expectedLine}, got: ${JSON.stringify(condition?.status ?? null)}.`,
    };
  }

  if (
    normalized.observedGeneration !== undefined &&
    String(condition.observedGeneration) !== String(normalized.observedGeneration)
  ) {
    return {
      pass: false,
      message: `Expected: the ${normalized.conditionType} condition of ${resource} to have observedGeneration ${normalized.observedGeneration}, got: ${condition.observedGeneration}.`,
    };
  }

  if (normalized.reason !== undefined && condition.reason !== normalized.reason) {
    return {
      pass: false,
      message: `Expected: the ${normalized.conditionType} condition of ${resource} to have reason "${normalized.reason}", got: ${JSON.stringify(condition.reason ?? null)}.`,
    };
  }

  return {
    pass: true,
    message: `${expectedLine}, got: "${condition.status}".`,
  };
}

// Pass only when the trimmed yq output equals the expected value. Any other
// output fails: a name_selector that matched no resource resolves an empty
// $NAME, the get returns the whole list, and the yq path evaluates to null
// on it (yq v4 prints `null`), so the comparison fails against the expected
// value.
export function compareKubernetesResourceProperty(config, output) {
  const normalized = normalizeKubernetesResourcePropertyConfig(config);
  const expected = String(normalized.expected);
  const actual = (output ?? "").trim();
  const resource = normalized.nameSelector
    ? `the ${normalized.kind} resolved by name_selector`
    : `${normalized.kind} ${normalized.name}`;

  return {
    pass: actual === expected,
    message: `Expected: the property ${normalized.path} of ${resource} to equal "${expected}", got: "${actual}".`,
  };
}
