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

## Allow requests carrying a valid token

This policy applies to every proxy in the mesh and rejects any request without a bearer token:

{% policy_yaml namespace=kong-mesh-demo %}
```yaml
type: MeshOPA
mesh: default
name: require-token
spec:
  targetRef:
    kind: Mesh
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

## Where this policy applies

`spec.targetRef` selects the proxies whose requests are authorized, and accepts `Mesh` or
`Dataplane` with `labels`. Everything else sits under `default`: the decision belongs to the
proxy handling the request, so there is no `to` or `rules`.

For the selectors a policy can carry, see [How policies select traffic](/mesh/policy-targeting/).

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
    what: "`secretRef: {kind: Secret, name: <name>}`, a {{site.mesh_product_name}} secret."
  - type: "`File`"
    what: "`file.path`, a path inside the sidecar container."
  - type: "`EnvVar`"
    what: "`envVar.name`, an environment variable on the sidecar."
  - type: "`InsecureInline`"
    what: "`insecureInline.value`, the content written in the policy as plain text."
{% endtable %}

`InsecureInline` is named for what it is: the content is stored in the policy and readable by
anyone who can read it. A rego policy is usually fine there, while an `agentConfig` carrying a
bearer token for a management server belongs in a `Secret`.

An inline rego policy is **compiled when the resource is applied**, so a syntax error is
rejected at write time with the OPA parse error attached — `policy is not valid: ...
rego_parse_error: unexpected eof token`. A policy supplied through `Secret`, `File` or `EnvVar`
is not compiled at write time, since the control plane does not read it, so an error there
surfaces only at the agent.

`appendPolicies[].ignoreDecision` keeps a policy loaded on the agent while leaving its verdict
out of the decision, which is how a new rule is exercised against real traffic before it starts
rejecting anything.

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
    what: "How long the proxy waits for a single decision from the agent."
  - field: "`requestBody.maxSize`"
    what: "How much of the request body to send to the agent. Bodies over the limit are truncated and marked with `x-envoy-auth-partial-body: true`. Unset, no body is sent."
  - field: "`requestBody.sendRawBody`"
    what: "Send the body as raw bytes rather than UTF-8 encoded."
{% endtable %}

`onAgentFailure` is the field that decides how the mesh behaves when OPA is unavailable. The
default of `Deny` fails closed: requests are rejected rather than passed through unauthorized.

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

{:.warning}
> Setting `requestBody` without `sendRawBody` currently fails inside the control plane's
> validator rather than returning a validation error. Set `sendRawBody` explicitly whenever
> `requestBody` is present, and set `maxSize` to a non-zero value, until that is fixed.

## Agent configuration

`default.agentConfig` is the OPA agent's own bootstrap configuration, in the format OPA expects,
which is how the agent is pointed at a bundle server or a decision log sink:

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
