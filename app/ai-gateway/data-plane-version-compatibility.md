---
title: "Data plane version compatibility"
content_type: reference
layout: reference

description: "Reference for how a {{site.ai_gateway}} control plane decides which data planes receive configuration. Covers the minimum supported data plane version, feature gating, and automatic raising of the minimum."

breadcrumbs:
  - /ai-gateway/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - konnect-api

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
  - text: "Upgrading {{site.event_gateway_short}}"
    url: /event-gateway/upgrade/

faqs:
  - q: Why did my data plane connect when its version is lower than the minimum supported data plane version?
    a: |
      A data plane below the minimum supported data plane version still connects to the {{site.ai_gateway}} control plane.
      This is expected, because connecting and receiving configuration are separate.
      The data plane appears in the {{site.konnect_short_name}} topology, but the control plane marks it as incompatible and sends it no configuration.

      For example, if the minimum is `2.2` and a `2.1` data plane connects, the node is listed with an incompatibility status and receives no updates.

  - q: What causes the control plane to reject a data plane?
    a: |
      Version compatibility doesn't disconnect a data plane from the {{site.ai_gateway}} control plane.
      A data plane below the minimum supported data plane version still connects, but it receives no configuration.

      A data plane fails to connect when the connection itself is invalid, for example because of incorrect connection parameters or certificates.
      These failures are unrelated to the minimum supported data plane version.

  - q: Do I need to track the control plane version?
    a: |
      No. The {{site.ai_gateway}} control plane version is decoupled from the data plane version.
      The only version setting you manage is the **Minimum supported data plane version**.

  - q: Is the minimum supported data plane version raised to a minor version or a patch version?
    a: |
      The minimum supported data plane version uses the `major.minor` format, for example `2.2`.
      Patch releases such as `2.2.0` and `2.2.1` count as the same version.
      Upgrading all of your data planes from `2.2.0` to `2.2.1` doesn't change the minimum, and rolling back to `2.2.0` doesn't affect configuration delivery.

  - q: What happens if I roll back a data plane to a lower minor version after the minimum supported data plane version was raised?
    a: |
      A rolled-back data plane connects to the {{site.ai_gateway}} control plane but is marked as incompatible and receives no configuration.
      For example, if all data planes move from `2.2` to `2.3` and the minimum is automatically raised to `2.3`, a data plane you roll back to `2.2` stops receiving updates.

      To receive configuration again, lower the minimum to the version you rolled back to.
      You can lower the minimum only when your configuration doesn't use any feature, field, or policy that requires a newer version.

  - q: Is automatic raising of the minimum supported data plane version enabled by default?
    a: |
      Yes. For a new {{site.ai_gateway}} control plane, **Automatically raise the minimum supported version** is enabled.
      To manage the minimum manually, disable the setting.

  - q: What happens if no data planes are connected and automatic raising is enabled?
    a: |
      When no data planes are connected, the minimum supported data plane version of the {{site.ai_gateway}} control plane stays at its current value.
      The control plane raises the minimum only based on versions reported by connected data planes.
      To use features from a newer version before any data plane connects, set the minimum manually.

  - q: Can I set the minimum supported data plane version to `latest`?
    a: |
      No. The minimum supported data plane version is always a specific `major.minor` version.
      If you don't set a value when you create a {{site.ai_gateway}} control plane, the latest generally available version is used.

  - q: Can I run multiple data plane versions at the same time?
    a: |
      Yes. A {{site.ai_gateway}} control plane sends configuration to data planes at or above the minimum supported data plane version.
      Data planes below the minimum connect but receive no configuration.
---

An {{site.ai_gateway}} control plane generates configuration for the data planes connected to it.
Newer data plane versions can support features that older versions don't, so the control plane needs to know which data plane versions it can safely configure.
Set the **Minimum supported data plane version** to define which versions receive configuration.

The control plane never sends configuration that a connected data plane can't run.
It enables a feature only when the minimum supported data plane version reaches the version that supports it.

## How the minimum supported data plane version works

The minimum supported data plane version is the lowest data plane version that can receive configuration from a control plane.
It applies to the control plane, so every data plane connected to it follows the same rule.

The setting controls the following:

{% table %}
columns:
  - title: Area
    key: area
  - title: Effect
    key: effect
rows:
  - area: "Configuration delivery"
    effect: "Data planes at or above the minimum receive configuration. Data planes below the minimum connect but receive no configuration."
  - area: "Feature availability"
    effect: "The {{site.konnect_short_name}} API and UI accept only the fields and policies supported at the minimum version."
  - area: "Generated configuration"
    effect: "The control plane generates configuration that is compatible with the minimum version."
{% endtable %}

Versions use the `major.minor` format and are compared by major version first, then minor version.
Patch versions aren't part of the comparison.

### Data planes below the minimum

A data plane below the minimum version still connects to the control plane, so you can see it in the {{site.konnect_short_name}} topology.
The control plane marks the data plane as incompatible and sends it no configuration.

Connecting and receiving configuration are separate.
A data plane below the minimum stays connected but receives no configuration.

### Feature gating

Feature gating blocks configuration that needs a newer data plane version than the control plane minimum.
Some entities and fields require a minimum data plane version.
If a request sets one of these fields and the control plane minimum is lower than the version the field requires, the API rejects the request.
The UI hides or disables these fields.

To use a feature introduced in a newer data plane version:

1. Upgrade your data planes to the version that introduces the feature.
1. Raise the **Minimum supported data plane version** to that version, or let the control plane raise it with [automatic raising](#automatically-raise-the-minimum-supported-version).

The control plane enables the feature only when the minimum reaches the version that supports it.

Feature gating also applies to wildcard values.
On an [AI Model](/ai-gateway/entities/ai-model/), setting `capabilities` or a format `type` to `*` allows everything that the targets support at the current minimum.
A capability or format that needs a newer version than the minimum is left out of `*` until you raise the minimum.

## Set the minimum supported data plane version

You can set the minimum supported data plane version when you create a control plane and change it later.
In the {{site.konnect_short_name}} UI, use **Minimum supported data plane version**.
With the API, use the `min_runtime_version` field.

The following rules apply when you change the value:

* You can always raise the minimum.
* You can lower the minimum only when your configuration doesn't use any feature, field, or policy that requires a version above the new value. Otherwise, the control plane blocks the change, and you must remove or change those features first.
* The value must be a specific released `major.minor` version, such as `2.2`.

If you don't specify a minimum when you create a control plane, the control plane uses the latest generally available version.
If you update a control plane without specifying a minimum, the value stays unchanged.

The following request raises the minimum supported data plane version to `2.3` by sending only `min_runtime_version` to the [`/v1/ai-gateways/{gatewayId}` endpoint](/api/konnect/ai-gateway/#/operations/patch-ai-gateway):

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

To keep control of when the minimum changes, send `runtime_auto_upgrade` set to `false` in the same endpoint:

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

## Automatically raise the minimum supported version

Automatic raising of the minimum supported version keeps the minimum in step with your data plane fleet, so you don't have to update it after each upgrade.
The **Automatically raise the minimum supported version** setting controls it, and the `runtime_auto_upgrade` field controls it in the API.
The setting is enabled by default.

When the setting is enabled, the control plane raises the minimum to the lowest version reported across the connected data planes as that version increases.
For example, if the minimum is `2.2` and you upgrade your last `2.2` data plane to `2.3`, the minimum becomes `2.3`.

Keep the following in mind:

* Automatic raising only increases the minimum and never lowers it.
* Automatic raising can replace a minimum you set manually.
* If no data planes are connected, the minimum doesn't change.
* Patch upgrades don't change the minimum, because it uses the `major.minor` format.

If you don't want to update the minimum after every upgrade, leave automatic raising enabled.
The minimum follows your fleet, so new features become available as soon as your last older data plane is upgraded.

If you want to decide when new features become available, or keep the option to roll data planes back to a lower minor version, disable automatic raising and set the minimum manually.
The minimum then changes only when you change it.

{:.warning}
> After the control plane raises the minimum, a data plane running a lower minor version receives no configuration. This applies to a data plane you roll back and to one that reconnects after being offline during an upgrade. Before you roll back a data plane to a lower minor version, check the current minimum and lower it if your configuration allows it. To prevent automatic raising, disable **Automatically raise the minimum supported version**.
