---
title: Mesh OPA
name: MeshOPAs
products:
- mesh
description: Authorize requests with Open Policy Agent, using rego policies evaluated by an agent beside each proxy.
content_type: plugin
tier: enterprise
icon: policy.svg
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3
  url: "/mesh/migrate-policies-to-3/#meshopa"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

`MeshOPA` authorizes requests with [Open Policy Agent](https://www.openpolicyagent.org/). The
proxy asks an OPA agent running beside it whether to allow each request, and the agent decides
by evaluating rego policies against the request's attributes.

This is a different question from the one
[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) answers. That decides whether one
workload may talk to another, from the identity in the TLS handshake. `MeshOPA` decides per
request, with the method, path, headers and optionally the body available to the policy, so it
covers rules that depend on what is being asked rather than only on who is asking.

The check runs on the destination's inbound HTTP traffic, including HTTP/2 and gRPC
handled as HTTP. It does not inspect arbitrary TCP messages or application-encrypted
traffic that the proxy cannot decrypt. An OPA allow does not override a denial from
`MeshTrafficPermission`; traffic must pass all applicable authorization checks.

Without a matching `MeshOPA`, this policy adds no OPA authorization check. Before relying
on a policy, confirm that the data-plane process has its embedded OPA agent enabled and
that the inbound listener contains `envoy.filters.http.ext_authz`. The data-plane option
`--opa-enabled` defaults to `true`, but can be disabled. A disabled agent that never
advertises an authorization port is different from an installed check whose agent fails:
`onAgentFailure: Deny` does not install a missing check.

## Allow requests carrying a bearer token

This demonstration selects destination proxies labeled `app: backend` and checks the shape
of the authorization header. It is not token validation. Test it on a non-production
workload whose caller already passes the required traffic permissions:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshOPA
mesh: default
name: require-token
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  default:
    appendPolicies:
      - rego:
          type: InsecureInline
          insecureInline:
            value: |
              package envoy.authz

              import input.attributes.request.http as http_request

              default allow = false

              allow {
                startswith(http_request.headers.authorization, "Bearer ")
              }
```
{% endpolicy_yaml %}

`targetRef` selects the backend proxies that enforce the check. The inline rego sets the default
decision to deny, then allows a request when its `authorization` header starts with `Bearer `.
This example checks only the header shape; it does not validate a signature, expiry, audience,
or any other token claim. A production policy must implement the token checks your application
requires.

## Where this policy applies

`spec.targetRef` selects the proxies whose requests are authorized, and accepts `Mesh` or
`Dataplane` with `labels`. Everything else sits under `default`: the decision belongs to the
proxy handling the request, so there is no `to` or `rules`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

## How policy decisions combine

Applicable `appendPolicies` lists accumulate; a workload-specific list does not replace
the mesh-wide list. For each entry participating in the decision, the generated combined
policy requires its package's `allow` to be true and its `deny` not to be true. All such
checks must pass. A missing or false `allow` therefore cannot authorize a request.

For example, a mesh-wide token check and a backend-specific method check both apply to
backend requests. Adding an allow-all policy for backend does not override the token
check. Use distinct Rego packages for independent checks: modules in the same package
share rules and data rather than becoming isolated decisions.

Conflicting `authConfig` fields and the selected `agentConfig` follow policy precedence.
Review the combined configuration before changing failure behavior for a subset of
workloads. To remove one inherited authorization requirement, change the broader policy's
scope or content; an empty narrower `appendPolicies` list does not subtract it.

## Providing rego and agent configuration

`appendPolicies[].rego` and `agentConfig` both take a **secure data source**: a `type`
discriminator naming where the data comes from, and a field of the same name carrying it.

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Where the data comes from
    key: what
rows:
  - type: "`Secret`"
    what: "`secretRef: {kind: Secret, name: SECRET_NAME}`, a secret resolved by the control plane in the policy's mesh."
  - type: "`File`"
    what: "`file.path`, a file readable by the control plane, not a path in the application or sidecar container."
  - type: "`EnvVar`"
    what: "`envVar.name`, an environment variable available to the control-plane process."
  - type: "`InsecureInline`"
    what: "`insecureInline.value`, the content written in the policy as plain text."
{% endtable %}

`InsecureInline` is named for what it is: the content is stored in the policy and readable by
anyone who can read it. A rego policy is usually fine there, while an `agentConfig` carrying a
bearer token for a management server belongs in a `Secret`.

An inline rego policy is **compiled when the resource is applied**, so a syntax error is
rejected at write time with the OPA parse error attached — `policy is not valid: ...
rego_parse_error: unexpected eof token`. A policy supplied through `Secret`, `File` or `EnvVar`
is not compiled during that resource-write validation. The control plane resolves the
source and compiles the combined modules when generating the agent configuration, so
missing sources or incompatible modules can fail at that later stage. Successful resource
creation alone does not prove that the agent received a working policy.

`appendPolicies[].ignoreDecision` keeps a policy loaded on the agent while leaving its verdict
out of the generated authorization decision. This can support shared helper modules, but
does not automatically evaluate an independent ignored rule or record its hypothetical
verdict. Test new rules explicitly before treating them as validated shadow checks.

## Configuring the request check

`default.authConfig` covers the exchange between the proxy and the agent.

{% table %}
columns:
  - title: Field
    key: field
  - title: Effect
    key: what
rows:
  - field: "`onAgentFailure`"
    what: "`Allow` or `Deny`, and `Deny` by default. What to do when the proxy cannot reach the agent or the policy fails to execute."
  - field: "`statusOnError`"
    what: "The HTTP status returned when the proxy cannot reach the agent. Between 100 and 599, or 0 to leave it to Envoy."
  - field: "`timeout`"
    what: "How long the proxy waits for a single decision from the agent. Defaults to 500ms; 0 also uses that default."
  - field: "`requestBody.maxSize`"
    what: "How much of the request body to send to the agent. Bodies over the limit are truncated and marked with `x-envoy-auth-partial-body: true`. Unset, no body is sent."
  - field: "`requestBody.sendRawBody`"
    what: "Send the body as raw bytes rather than UTF-8 encoded."
{% endtable %}

`onAgentFailure` is the field that decides how the mesh behaves when OPA is unavailable. The
default of `Deny` fails closed: requests are rejected rather than passed through unauthorized.

`Allow` applies to an agent communication or execution failure, not to an explicit deny
decision. `statusOnError` similarly controls error responses, not the normal deny response
from a working agent. Choose the decision timeout within the caller's overall request
budget: waiting longer for authorization adds latency before application processing begins.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshOPA
mesh: default
name: authorize-with-body
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
  default:
    authConfig:
      onAgentFailure: Deny
      statusOnError: 503
      timeout: 1s
      requestBody:
        maxSize: 8192
        sendRawBody: false
    appendPolicies:
      - rego:
          type: Secret
          secretRef:
            kind: Secret
            name: backend-authz-policy
```
{% endpolicy_yaml %}

Create `backend-authz-policy` in the policy's mesh before applying this example, with a
Rego module defining the required `allow` decision. Confirm that the control plane can
resolve it and that the agent loads the generated configuration.

Body buffering sends at most `maxSize` bytes to OPA. A larger request is not automatically
denied: the authorization input can be partial. If a decision requires the complete body,
make the policy reject partial input rather than authorizing from an incomplete document.
Also test empty and malformed bodies. Sending raw bytes changes the input representation;
it does not guarantee a parsed JSON body. See the
[OPA request-input reference](https://www.openpolicyagent.org/docs/envoy/primer#input-document).

{:.warning}
> Setting `requestBody` without `sendRawBody` currently fails inside the control plane's
> validator rather than returning a validation error. Set `sendRawBody` explicitly whenever
> `requestBody` is present, and set `maxSize` to a non-zero value, until that is fixed.

## Agent configuration

`default.agentConfig` is the OPA agent's own bootstrap configuration, in the format OPA expects,
which is how the agent is pointed at a bundle server or a decision log sink:

The following is a diagnostic example, not a production authorization policy: its Rego
allows every request that reaches the OPA check. Use it only on test workloads, or retain
your real authorization modules when adding decision logging.

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshOPA
mesh: default
name: opa-decision-logs
spec:
  targetRef:
    kind: Mesh
  default:
    agentConfig:
      type: InsecureInline
      insecureInline:
        value: |
          decision_logs:
            console: true
    appendPolicies:
      - rego:
          type: InsecureInline
          insecureInline:
            value: |
              package envoy.authz
              default allow = true
```
{% endpolicy_yaml %}

Decision logs can contain request input, including headers and body data. Restrict access
to them and configure appropriate masking before sending them to shared log storage.
Do not place bundle-server credentials directly in an inline `agentConfig`.

## Validate the authorization decision

For the first example, send the same request without an `Authorization` header and with
`Authorization: Bearer test`. The request without the header should be rejected; the request
with it should pass this example's OPA check. Whether the allowed request succeeds afterward
still depends on the destination and any other authorization policy.

Then stop or disconnect the OPA agent and repeat the request. With the default
`onAgentFailure: Deny`, the request must be rejected. If you set `onAgentFailure: Allow`,
document that fail-open decision and test it deliberately.

Perform the agent-failure test on an isolated workload with the authorization filter
already installed. Disabling OPA before startup is not an equivalent test.

If the result is unexpected, distinguish these cases:

| Observation | Check |
| --- | --- |
| Requests bypass the expected check | Confirm destination selection, HTTP protocol handling, agent enablement, and the active `envoy.filters.http.ext_authz` filter. |
| Every request is denied | Inspect the combined modules and decision input; every participating package needs a true `allow` and no true `deny`. Also check traffic permissions separately. |
| The configured error status appears | Inspect agent availability, evaluation errors, and the decision timeout rather than assuming Rego deliberately denied the request. |
| A policy is stored but not active | Inspect control-plane source-loading and compilation errors, then verify the configuration actually loaded by the agent. |

For body-based decisions, include requests below and above `maxSize`. For overlapping
policies, test a request that passes each check individually but fails one of the combined
requirements. Remove diagnostic allow-all policies and restore the intended logging and
failure settings when the test ends.
