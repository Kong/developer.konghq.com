---
title: 'Harness AI Firewall'
name: 'Harness AI Firewall'

content_type: plugin
tier: enterprise
publisher: harness
description: 'Detect, redact, or block sensitive data in AI request and response traffic flowing through {{site.base_gateway}}'


products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.4'

third_party: true
premium_partner: true

support_url: https://www.harness.io/support

icon: harness.svg

search_aliases:
  - traceable ai extension
  - traceableai
  - ai firewall

tags:
  - ai
  - security

related_resources:
  - text: AI firewall extension documentation
    url: https://docs.traceable.ai/docs/kong#ai-firewall-extension
  - text: Harness WAAP plugin
    url: /plugins/harness-waap/
  - text: Premium partners
    url: /premium-partners/
---

Use the {{page.name}} plugin (`traceable-ai-extension`) to inspect AI request and response traffic flowing through {{site.base_gateway}} and apply the sensitive-data classification and data-protection rules you configure in the Harness Traceable Platform.

{{page.name}} is an extension of the [Harness WAAP](/plugins/harness-waap/) plugin and requires it to be installed and attached to the same Route or Service.
If your {{site.base_gateway}} deployment routes traffic to AI-powered services, attach {{page.name}} alongside Harness WAAP to protect that traffic before it reaches your upstream application or your client.
Based on the rules you configure in the Traceable Platform, the plugin can detect, redact, or block matching content in either direction.

Benefits of using the {{page.name}} plugin:

- **Request redaction:** Masks sensitive data before the request reaches the upstream application.
- **Response redaction:** Masks sensitive data before the response reaches the client.
- **Rule-driven enforcement:** The plugin only acts on content matched by rules you configure in the Traceable Platform. 
Nothing is redacted, denied, or flagged unless a rule says so.
- **Blocking:** A policy can deny matching traffic outright instead of redacting it.

## How it works

{{page.name}} shares configuration, including the TPA endpoint, token, service name, and environment name, with the [Harness WAAP](/plugins/harness-waap/) plugin already attached to the same Route or Service. It doesn't call the Traceable Platform Agent (TPA) directly.

Attaching {{page.name}} enables both request and response evaluation for that Route. The specific behavior for each direction is driven entirely by your platform rules.

When you enable this plugin on a Route, it acts in two {{site.base_gateway}} request-lifecycle phases:

- `access`: Evaluates the request body against your configured rules, and redacts or blocks matching content before the request is proxied upstream.
- `response`: Evaluates the complete upstream response body against your configured rules, and redacts matching content before it reaches the client.

{% mermaid %}
sequenceDiagram
    autonumber
    participant C as Client
    participant K as {{site.base_gateway}}<br/>harness-ai-firewall
    participant E as Edge Decision Service
    participant U as Upstream AI service

    C->>K: Request
    Note over K: access phase
    K->>E: Evaluate request body against rules
    E-->>K: Redact, allow, or deny
    K->>U: Request (redacted if matched)
    U-->>K: Response
    Note over K: response phase
    K->>E: Evaluate response body against rules
    E-->>K: Redact or allow
    K-->>C: Response (redacted if matched)
{% endmermaid %}

### Request evaluation

Request evaluation, redaction, and blocking require `mode: sync` on the base [Harness WAAP](/plugins/harness-waap/) plugin config for the same Route or Service.
Response evaluation and redaction aren't affected by the base plugin's mode.
For more information, see the [Harness WAAP plugin](/plugins/harness-waap/).

### Response buffering and streaming

{{page.name}} buffers the complete upstream response before evaluating it.
If you attach the plugin to a Route serving Server-Sent Events (SSE) or other long-lived streaming responses, those responses won't stream while the plugin is attached.
Large responses can also increase latency and memory usage while they're buffered for evaluation.

### Supported request content types

The plugin evaluates request bodies only when the `Content-Type` header contains one of the following:

- `json`
- `xml`
- `x-www-form-urlencoded`
- `text/event-stream`

It doesn't evaluate other request body types, including `text/plain`, protobuf, gRPC, octet-stream, and images.

### Failure behavior

Request and response evaluation each default to fail-open (`allow_on_failure: true`).
If the Edge Decision Service is unreachable, times out, or returns an invalid response, traffic passes through without redaction.
Set `allow_on_failure: false` on `request_config` or `response_config` to fail closed instead.
When evaluation fails closed, or when a policy denies matching traffic, the client receives a 403 response by default.

### Custom error response

You can customize the status code and message returned when the Traceable Platform Agent (TPA) blocks a request.
Configure this in the `injector` section of your TPA configuration:

```yaml
ext_cap:
  blocking_config:
    response_status_code: 403
    response_message: "Access Forbidden"
injector:
  blocking_config:
    response_status_code: 403
    response_message: "Access Forbidden"
```

If you deploy the TPA with Helm, set the equivalent fields in `values.yaml` instead:

```yaml
blockingStatusCode:
blockingMessage:
injector:
  blockingConfig:
    blockingStatusCode:
    blockingMessage:
```

{:.warning}
> **Note**: `response_status_code` must be between 400 and 499.
> If you set a value outside that range, the TPA falls back to the default status code, 403.

## Install the {{page.name}} plugin

LuaRock name: `kong-plugin-traceable` (current version `2.3.0-1`).
This is the same LuaRock used by the [Harness WAAP](/plugins/harness-waap/) plugin.
Installing it makes both the `traceable` and `traceable-ai-extension` plugins available to {{site.base_gateway}}.

### Prerequisites

Before installing the plugin, you need:

- A [Traceable Platform Agent (TPA)](https://docs.traceable.ai/docs/tpa) deployed in your environment, with Edge Decision Service (EDS) enabled and reachable from the TPA.
- The [Harness WAAP](/plugins/harness-waap/) plugin installed and configured on the same Route or Service. Use `mode: sync` if you need request evaluation, redaction, or blocking.
- Sensitive-data classification or data-protection rules configured in the Traceable Platform for the content you want to detect, redact, or block.

### Installation steps

{% navtabs 'install' %}
{% navtab "Self-managed" %}

1. Install the plugin using LuaRocks:

   ```bash
   luarocks install kong-plugin-traceable
   ```

1. Update your loaded plugins list in {{site.base_gateway}}.

   In your [`kong.conf`](/gateway/configuration/), append both `traceable` and `traceable-ai-extension` to the `plugins` field. Make sure the field isn't commented out.

   ```yaml
   plugins = bundled,traceable,traceable-ai-extension
   ```

1. Restart {{site.base_gateway}}:

   ```bash
   kong restart
   ```

{% endnavtab %}
{% navtab "Helm" %}

These steps apply to the Kong Kubernetes Ingress Controller.

1. Download and unpack the LuaRock:

   ```bash
   curl -fLO https://luarocks.org/manifests/traceableai/kong-plugin-traceable-2.3.0-1.src.rock
   ```

   ```bash
   luarocks unpack kong-plugin-traceable-2.3.0-1.src.rock
   ```

1. Create a configmap from the unpacked plugin files:

   ```bash
   kubectl create configmap -n kong kong-plugin-traceable --from-file ./kong-plugin-traceable-2.3.0-1/kong-plugin-traceable-2.3.0/kong/plugins/traceable/
   ```

   ```bash
   kubectl create configmap -n kong kong-plugin-traceable-ai-extension --from-file ./kong-plugin-traceable-2.3.0-1/kong-plugin-traceable-2.3.0/kong/plugins/traceable-ai-extension/
   ```

1. In your Kong Helm values file, add both plugin names to the existing `env` key, and reference both configmaps:

   ```yaml
   # This should be under the env key and should already exist.
   # If you have other third-party plugins, keep them in the list.
   plugins: bundled,traceable,traceable-ai-extension
   # Add this section at the very bottom of the file.
   plugins:
     configMaps:
     - name: kong-plugin-traceable
       pluginName: traceable
     - name: kong-plugin-traceable-ai-extension
       pluginName: traceable-ai-extension
   ```

1. Upgrade the deployment with the updated values file:

   ```bash
   helm upgrade quickstart kong/kong --namespace kong --values kong-values.yaml
   ```

{% endnavtab %}
{% endnavtabs %}

## Enable the plugin

After installing the plugin, enable {{page.name}} on the same Route or Service as the [Harness WAAP](/plugins/harness-waap/) plugin.
Set `mode: sync` on the base plugin if you need request evaluation, redaction, or blocking.
See the [Enable Harness AI Firewall example](/plugins/harness-ai-firewall/examples/enable-harness-ai-firewall/).

## Troubleshooting

### Traffic passes through unredacted when a rule should have matched

**Symptoms:** Requests or responses that should match a configured rule pass through unchanged.

**Possible solutions:**
- Confirm the rule is enabled in the Traceable Platform.
- Confirm the Route is covered by both the `traceable` and `traceable-ai-extension` plugins.
- Confirm the traffic reaches the Edge Decision Service.
- Confirm the payload content and `Content-Type` match the rule.
- Confirm the configured timeouts are sufficient for evaluation to complete.

{:.info}
> **Note**: A successful passthrough without redaction doesn't necessarily indicate a problem. It can mean that no configured platform rule matched your test traffic.

### The plugin has no effect

**Symptoms:** {{page.name}} is attached to a Route, but no evaluation appears to happen.

**Possible solutions:**
- Confirm the [Harness WAAP](/plugins/harness-waap/) plugin is also attached to the same Route or Service. `traceable-ai-extension` depends on the base plugin for the TPA endpoint and other shared configuration.
- Confirm the base plugin's `mode` is set to `sync`. Request evaluation doesn't run in `async` mode.
