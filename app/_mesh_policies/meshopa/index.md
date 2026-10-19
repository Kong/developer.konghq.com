---
title: Mesh OPA
name: MeshOPAs
products:
- mesh
description: Authorize requests with Open Policy Agent, using Rego policies evaluated by an agent beside each proxy.
content_type: plugin
tier: enterprise
icon: policy.svg
related_resources:
- text: How policies select traffic
  url: "/mesh/policy-targeting/"
- text: Migrate policies to {{site.mesh_product_name}} 3.x
  url: "/mesh/migrate-policies-to-3/#meshopa"
- text: MeshTrafficPermission policy
  url: "/mesh/policies/meshtrafficpermission/"
---

The `MeshOPA` policy authorizes requests with [Open Policy Agent](https://www.openpolicyagent.org/).
The proxy asks an OPA agent running beside it whether to allow each request, and the agent
evaluates Rego policies against the request's attributes.

[MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) decides whether one workload can
talk to another, based on the identity in the TLS handshake. `MeshOPA` decides per request,
using the method, path, headers, and optionally the body, so it can enforce rules based on what's
being asked, not only on who's asking.

The check runs on the destination's inbound HTTP traffic, including HTTP/2 and gRPC. It doesn't
inspect plain TCP traffic or traffic the proxy can't decrypt. An OPA allow doesn't override a
`MeshTrafficPermission` deny: traffic must pass every authorization check.

Proxies that no `MeshOPA` selects get no OPA check. Before relying on a policy, confirm the
following:

* The data plane has its embedded OPA agent enabled. The `--opa-enabled` option defaults to
  `true`, but can be turned off.
* The inbound listener contains `envoy.filters.http.ext_authz`.

If the agent is disabled, no check is installed, and `onAgentFailure: Deny` doesn't change that.
It only applies when an installed check's agent fails.

## Allow requests carrying a bearer token

The following example makes proxies labeled `app: backend` deny requests unless their
`authorization` header starts with `Bearer `. Test it on a non-production workload whose caller
already passes the required traffic permissions:

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

`targetRef` selects the backend proxies that enforce the check: `Mesh`, or `Dataplane` with
`labels`. Everything else goes under `default`. There's no `to` or `rules`, because the proxy
handling the request makes the decision.

The example only checks the header shape. It doesn't validate the token's signature, expiry,
audience, or other claims, so a production policy must implement the checks your application
needs.

## Provide Rego and agent configuration

`appendPolicies[].rego` and `agentConfig` both take a secure data source: a `type` that says
where the data comes from, and a field of the same name that holds it. `type` accepts the
following values:

{% table %}
columns:
  - title: "`type`"
    key: type
  - title: Where the data comes from
    key: what
rows:
  - type: "`Secret`"
    what: "A secret in the policy's mesh, resolved by the control plane. Set it with `secretRef: {kind: Secret, name: SECRET_NAME}`."
  - type: "`File`"
    what: "A file the control plane can read, set with `file.path`. It isn't a path in the application or sidecar container."
  - type: "`EnvVar`"
    what: "An environment variable of the control plane process, set with `envVar.name`."
  - type: "`InsecureInline`"
    what: "Plain text in the policy, set with `insecureInline.value`."
{% endtable %}

Inline content is readable by anyone who can read the policy. Inline Rego is usually fine, but
put an `agentConfig` that carries a management server token in a `Secret`.

Inline Rego is compiled when the resource is applied, so a syntax error is rejected with the
OPA parse error. Rego from `Secret`, `File`, or `EnvVar` is only compiled later, when the control
plane generates the agent configuration, so missing sources or incompatible modules fail then.
A successfully created resource doesn't prove that the agent has a working policy.

`appendPolicies[].ignoreDecision` keeps a policy loaded on the agent, but leaves its result out
of the decision. This is useful for shared helper modules. It doesn't evaluate an ignored rule
on its own or record what it would have decided, so test new rules explicitly instead of
treating them as shadow checks.

## Configure the request check

`default.authConfig` controls the exchange between the proxy and the agent, and accepts the
following fields:

{% table %}
columns:
  - title: Field
    key: field
  - title: Effect
    key: what
rows:
  - field: "`onAgentFailure`"
    what: "What to do when the proxy can't reach the agent or the policy fails to run: `Allow` or `Deny`. Defaults to `Deny`, which rejects requests instead of passing them through unauthorized."
  - field: "`statusOnError`"
    what: "The HTTP status returned when the proxy can't reach the agent, from 100 to 599. `0` leaves it to Envoy."
  - field: "`timeout`"
    what: "How long the proxy waits for one decision. Defaults to 500ms, and `0` also uses the default."
  - field: "`requestBody.maxSize`"
    what: "How much of the request body to send to the agent. Larger bodies are truncated and marked with `x-envoy-auth-partial-body: true`. If unset or `0`, no body is sent."
  - field: "`requestBody.sendRawBody`"
    what: "Sends the body as raw bytes instead of UTF-8. Defaults to `false`. Setting it to `true` without a `maxSize` above `0` is rejected."
{% endtable %}

`Allow` only applies to agent communication or execution failures, not to a deny decision.
Likewise, `statusOnError` only sets the error response, not the deny response from a working
agent. Keep the timeout within the caller's overall request budget, because authorization adds
latency before the application sees the request.

The following example sends up to 8192 bytes of the request body to the agent, and reads its
Rego from a secret. Before applying it, create `backend-authz-policy` in the policy's mesh, with
a Rego module that defines `allow`:

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

Confirm that the control plane can resolve the secret and that the agent loads the generated
configuration.

A request larger than `maxSize` isn't denied automatically: OPA gets partial input. If a
decision needs the full body, make the policy reject partial input. Also test empty and
malformed bodies. Sending raw bytes changes the input format, but doesn't guarantee a parsed
JSON body. For more information, see the
[OPA request input reference](https://www.openpolicyagent.org/docs/envoy/primer#input-document).

## Configure the OPA agent

`default.agentConfig` is the OPA agent's own bootstrap configuration, in OPA's format. Use it to
point the agent at a bundle server or a decision log sink.

The following example enables console decision logs. Its Rego allows every request that reaches
the OPA check, so only use it on test workloads, or keep your real authorization modules when
adding decision logging:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshOPA
mesh: default
name: opa-decision-logs
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: backend
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
              package diagnostics.allow_all
              default allow = true
```
{% endpolicy_yaml %}

Decision logs can contain request input, including headers and body data. Restrict access to
them, and set up masking before sending them to shared log storage. Don't put bundle server
credentials in an inline `agentConfig`.

## Overlapping policies

When several MeshOPA policies apply to the same proxy, their `appendPolicies` lists are
combined. A workload-specific policy adds its entries to the mesh-wide ones instead of
replacing them.

A request is allowed only if every combined entry allows it: each entry's Rego package must set
`allow` to true and must not set `deny` to true. If a package doesn't define `allow`, or sets it
to false, the request is denied. Entries with `ignoreDecision: true` are left out of this check.

For example, a mesh-wide token check and a backend-specific method check both apply to backend
requests, and adding an allow-all policy for backend doesn't override the token check. Use
separate Rego packages for independent checks, because modules in the same package share rules
and data.

Conflicting `authConfig` fields and the selected `agentConfig` follow policy precedence, so
review the combined configuration before changing failure behavior for some workloads. To remove
an inherited check, change the broader policy's scope or content. An empty `appendPolicies` list
in a narrower policy doesn't remove it.

## Validating the authorization decision

1. For the first example, send one request without an `Authorization` header and one with
   `Authorization: Bearer test`. Confirm that the first is rejected and the second passes the
   OPA check. Whether it then succeeds depends on the destination and other authorization
   policies.
1. On an isolated workload with the authorization filter already installed, stop or disconnect
   the OPA agent and repeat the request. With the default `onAgentFailure: Deny`, confirm that
   the request is rejected. If you set `onAgentFailure: Allow`, document that fail-open choice
   and test it deliberately. Disabling OPA before startup isn't an equivalent test.
1. For body-based decisions, send requests smaller and larger than `maxSize`.
1. For overlapping policies, send a request that passes each check alone but fails one of the
   combined requirements.
1. When the test ends, remove diagnostic allow-all policies and restore your logging and failure
   settings.

If the result is unexpected, check the following:

{% table %}
columns:
  - title: Observation
    key: observation
  - title: Check
    key: check
rows:
  - observation: "Requests bypass the expected check"
    check: "Destination selection, HTTP handling, whether the agent is enabled, and whether `envoy.filters.http.ext_authz` is active."
  - observation: "Every request is denied"
    check: "Inspect the combined modules and the decision input. Every participating package needs a true `allow` and no true `deny`. Review traffic permissions separately."
  - observation: "The configured error status appears"
    check: "Agent availability, evaluation errors, and the decision timeout. Rego didn't necessarily deny the request."
  - observation: "A policy is stored but not active"
    check: "Source loading and compilation errors on the control plane, then the configuration the agent actually loaded."
{% endtable %}
