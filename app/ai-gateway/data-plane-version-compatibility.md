---
title: "Data plane version compatibility"
content_type: reference
layout: reference

description: "Reference for how an {{site.ai_gateway}} control plane determines which data planes are compatible with its configuration. Covers the minimum supported data plane version, feature gating, and automatic raising of the minimum."

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - konnect-api
  - kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - compatibility
  - control-plane
  - data-plane

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: "{{site.ai_gateway}} version support policy"
    url: /ai-gateway/version-support-policy/
  - text: "{{site.ai_gateway}} changelog"
    url: /ai-gateway/changelog/

faqs:

  - q: What causes the control plane to reject a data plane?
    a: |
      A version below the minimum supported data plane version doesn't stop a data plane from connecting to the {{site.ai_gateway}} control plane.

      A data plane fails to connect when the connection itself is invalid, for example because of incorrect connection parameters or certificates.
      These failures are unrelated to the minimum supported data plane version.

  - q: Do I need to track the control plane version?
    a: |
      No. The {{site.ai_gateway}} control plane version is decoupled from the data plane version.
      The only version setting you manage is the **Minimum supported data plane version**.

  - q: Can I set the minimum supported data plane version to `latest`?
    a: |
      No. The minimum supported data plane version is always a specific `major.minor` version.
      If you don't set a value when you create a {{site.ai_gateway}} control plane, the latest generally available version is used.

  - q: Can I run multiple data plane versions at the same time?
    a: |
      Yes. Data planes at or above the minimum supported data plane version run any configuration that the {{site.ai_gateway}} control plane accepts.
      Data planes below the minimum also work when the configuration doesn't use a feature that requires a newer version.
---

An {{site.ai_gateway}} control plane generates configuration for the data planes connected to it.
Newer data plane versions can support features that older versions don't, so the control plane needs to know which features it can safely configure.
Set the **Minimum supported data plane version** to define which features the control plane accepts.

Data planes at or above the minimum can run any configuration the control plane accepts.
A data plane below the minimum also works when your configuration doesn't use a feature that requires a newer version.

## How the minimum supported data plane version works

The minimum supported data plane version is the lowest data plane version that is guaranteed to run any configuration the control plane accepts.
It applies to the control plane, so every data plane connected to it follows the same rule.

The setting controls the following:

{% table %}
columns:
  - title: Area
    key: area
  - title: Effect
    key: effect
rows:
  - area: "Feature availability"
    effect: "The {{site.konnect_short_name}} API accepts only the fields and policies supported at the minimum version, and the UI disables the others."
  - area: "Generated configuration"
    effect: "The control plane generates configuration that is compatible with the minimum version."
  - area: "Data plane compatibility"
    effect: "Whether a data plane is compatible depends on its version and the features your configuration uses."
{% endtable %}

Versions use the `major.minor` format and are compared by major version first, then minor version.
Patch versions aren't part of the comparison.

### Data plane compatibility

Data plane compatibility describes whether a data plane can receive the configuration and apply all of its entities and features.
The {{site.konnect_short_name}} UI shows a compatible data plane as **Compatible**.
Every data plane connects to the control plane and appears in the {{site.konnect_short_name}} topology, regardless of its version.

A data plane is compatible in either of the following cases:

* The data plane version is at or above the minimum supported data plane version.
* The data plane version is below the minimum, but your configuration doesn't use any feature that requires a newer version.

For example, if the minimum is `2.2` and a `2.1` data plane connects, the data plane is compatible when your configuration uses no feature that needs a version above `2.1`.

### Feature gating

Feature gating blocks configuration that needs a newer data plane version than the control plane minimum.
Some entities and fields require a minimum data plane version.
If a request sets one of these fields and the control plane minimum is lower than the version the field requires, the API rejects the request.
The UI disables these fields.

To use a feature introduced in a newer data plane version:

1. Upgrade your data planes to the version that introduces the feature.
1. Raise the **Minimum supported data plane version** to that version, or let the control plane raise it with [automatic raising](#automatically-raise-the-minimum-supported-version).

Feature gating also applies to wildcard values.
On an [AI Model](/ai-gateway/entities/ai-model/), setting `capabilities` or a format `type` to `*` allows everything that the targets support at the current minimum.
A capability or format that needs a newer version than the minimum is left out of `*` until you raise the minimum.

## Set the minimum supported data plane version

You can set the minimum supported data plane version when you create a control plane and change it later.
In the {{site.konnect_short_name}} UI, use **Minimum supported data plane version**.
With the API, use the `min_runtime_version` field.

The following rules apply when you change the value:

* You can always raise the minimum.
* You can lower the minimum only when your configuration doesn't use any feature, field, or policy that requires a version above the new value.
  Otherwise, the control plane blocks the change, and you must remove or change those features first.
* The value must be a specific released `major.minor` version, such as `2.2`.

If you don't specify a minimum when you create a control plane, the control plane uses the latest generally available version.
If you update a control plane without specifying a minimum, the value stays unchanged.

The following examples raise the minimum supported data plane version to `2.3` by setting only `min_runtime_version`.
The API request uses the [`/v1/ai-gateways/{gatewayId}` endpoint](/api/konnect/ai-gateway/#/operations/patch-ai-gateway).

The kongctl examples require kongctl 1.23.0 or later.

{% navtabs "raise-minimum" %}
{% navtab "Konnect API" %}
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID
status_code: 200
method: PATCH
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  min_runtime_version: '2.3'
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "kongctl" %}
```yaml
ai_gateways:
  - ref: my-ai-gateway
    display_name: My AI Gateway
    min_runtime_version: '2.3'
```
{% endnavtab %}
{% endnavtabs %}

To keep control of when the minimum changes, set `runtime_auto_upgrade` to `false`:

{% navtabs "disable-auto-raise" %}
{% navtab "Konnect API" %}
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID
status_code: 200
method: PATCH
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  runtime_auto_upgrade: false
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "kongctl" %}
```yaml
ai_gateways:
  - ref: my-ai-gateway
    display_name: My AI Gateway
    runtime_auto_upgrade: false
```
{% endnavtab %}
{% endnavtabs %}

## Automatically raise the minimum supported version

Automatic raising of the minimum supported version keeps the minimum in step with your data plane fleet, so you don't have to update it after each upgrade.
Use the **Automatically raise the minimum supported version** setting in the UI or the `runtime_auto_upgrade` field in the API to control it.
The setting is enabled by default.

When the setting is enabled, the control plane raises the minimum to the lowest version among the connected data planes.
The raise happens after all connected data planes run the newer version and have synced their configuration correctly.
For example, if the minimum is `2.2` and you upgrade all of your data planes to `2.3`, the minimum becomes `2.3` once every data plane runs `2.3` and is in sync.

Automatic raising behaves as follows:

* Automatic raising only increases the minimum and never lowers it.
* Automatic raising can replace a minimum you set manually.
* If no data planes are connected, the minimum doesn't change.

If you don't want to update the minimum manually after every upgrade, leave automatic raising enabled.
The minimum follows your fleet, so new features become available once all of your data planes run the newer version.

If you want to decide when new features become available, disable automatic raising and set the minimum manually.
The minimum then changes only when you change it.

## Roll back a data plane

You can roll back a data plane to a lower minor version in either of the following ways:

1. Roll back only the data plane.
   This works when your configuration doesn't use any feature that requires a newer version.
   For example, if the control plane and all data planes run `2.3`, rolling back one data plane to `2.2` works when you don't use any `2.3` feature.
1. Disable automatic raising, set the minimum to the lower version, and then roll back the data plane.
   You can lower the minimum only when your configuration doesn't use any feature that requires a newer version.
