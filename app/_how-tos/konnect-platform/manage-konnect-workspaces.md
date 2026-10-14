---
title: Manage Workspaces in Konnect
content_type: how_to
description: Create and manage Workspaces in a Konnect control plane to isolate Gateway entities across teams.
products:
  - gateway
works_on:
  - konnect
tools:
  - konnect-api
  - deck
tldr:
  q: How do I create and manage Workspaces in a {{site.konnect_short_name}} control plane?
  a: "Create a Workspace by sending a POST request to the `/control-planes/$CONTROL_PLANE_ID/core-entities/workspaces` endpoint. You can manage Workspace entities by sending a POST request to the entities endpoint, for example: `/control-planes/$CONTROL_PLANE_ID/core-entities/$WORKSPACE/services`."
tags:
  - rbac
entities:
  - workspace
permalink: /how-to/manage-konnect-workspaces/
related_resources:
  - text: Workspace entity reference
    url: /gateway/entities/workspace/

prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        To use this tutorial, you need one of the following [{{site.konnect_short_name}} roles](/konnect-platform/teams-and-roles/#workspaces):
        * `Admin` on the control plane, or `Workspace Creator`, to create a Workspace
        * `Workspace Admin` on the Workspace you want to manage
      icon_url: /assets/icons/gateway.svg
---

## Create a Workspace

A [Workspace](/gateway/entities/workspace/) is a namespace for Gateway entities inside a {{site.konnect_short_name}} control plane. Entities in one Workspace are invisible to and independent of entities in another. Data planes attach to the parent control plane and serve traffic across all of its Workspaces.

Every control plane has a `default` Workspace.
Any entities created before additional Workspaces are added live there, as well as any CA certificates.
For example, a plugin in the `default` Workspace applies only to entities in the `default` Workspace, not across all Workspaces.
Entity names can repeat across Workspaces: two Workspaces can each have a Consumer named `alice`, with different credentials on each.

1. Look up the ID of the control plane you want to add Workspaces to, by name, and capture it as `$CONTROL_PLANE_ID`:
{% capture get-control-plane-id %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ get-control-plane-id | indent: 3}}

   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```

1. List existing Workspaces on the control plane:
{% capture list-workspaces %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/workspaces
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ list-workspaces | indent: 3}}
1. Create a new Workspace:
{% capture create-workspace %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/workspaces
status_code: 201
method: POST
body:
    name: team-payments
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-workspace | indent: 3}}
   You can reference a Workspace by name or by ID in any subsequent API path.

## Manage entities in a Workspace

1. Export the Workspace name:

   ```sh
   export WORKSPACE='team-payments'
   ```
1. Create a Gateway Service in the Workspace, and capture its ID as `$SERVICE_ID`:
{% capture create-service %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/$WORKSPACE/services
status_code: 201
method: POST
body:
    name: payment-api
    url: http://payment-service.internal:8080
capture:
  - variable: SERVICE_ID
    jq: '.id'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-service | indent: 3}}
1. Create a Route in the Workspace, referencing the Service:
{% capture create-route %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/$WORKSPACE/routes
status_code: 201
method: POST
body:
    name: payment-route
    paths:
        - /payments
    service:
        id: $SERVICE_ID
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-route | indent: 3}}

{:.info}
> Entities in the `default` Workspace use the existing un-prefixed path, for example `.../core-entities/services`.

## Custom plugins

Install custom plugin schemas at the control plane level, in the `default` Workspace.
Once installed, you can create plugin instances of that custom plugin in any Workspace on the control plane, the same way you would with a bundled plugin.

1. Upload a custom plugin schema at the control plane level, by sending a `POST` request to the [`/custom-plugins` endpoint](/api/konnect/control-planes-config/#/operations/create-custom-plugin):
{% capture create-custom-plugin %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/custom-plugins
status_code: 201
method: POST
body:
    name: set-header
    handler: 'return { VERSION = "1.0.0", PRIORITY = 500, access = function(self, config) kong.service.request.set_header(config.name, config.value) end }'
    schema: 'return { name = "set-header", fields = { { config = { type = "record", fields = { { name = { type = "string", required = true } }, { value = { type = "string", required = true } } } } } } }'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-custom-plugin | indent: 3}}
1. Create an instance of the plugin in the Workspace, by sending a `POST` request to the [`/plugins` endpoint](/api/konnect/control-planes-config/#/operations/create-plugin):
{% capture create-plugin-instance %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/$WORKSPACE/plugins
status_code: 201
method: POST
body:
    name: set-header
    config:
        name: X-Team
        value: payments
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create-plugin-instance | indent: 3}}

{:.warning}
> You can't install schemas in a non-default Workspace.

## Use decK

To use decK with {{site.konnect_short_name}} Workspaces, you need 1.43 or later, but 1.60 or later is recommended.

{:.warning}
> **Set your decK environment variables:**
> You must set decK environment variables with your {{site.konnect_short_name}} access token and address for the following decK commands to work. For example:
> ```sh
> export DECK_KONNECT_TOKEN="kpat_..."
> export DECK_KONNECT_ADDR="https://us.api.konghq.com"
> ```
> If you [created a control plane in the prerequisites](#kong-konnect), your environment variables should already be set.

1. Dump one Workspace:

   ```sh
   deck gateway dump --konnect-control-plane-name quickstart --workspace team-payments -o team-payments.yaml
   ```
1. Dump every Workspace into separate files:

   ```sh
   deck gateway dump --konnect-control-plane-name quickstart --all-workspaces
   ```
1. Apply a config file into a Workspace:

   ```sh
   deck gateway sync team-payments.yaml --konnect-control-plane-name quickstart --workspace team-payments
   ```

A dumped file carries a `_workspace:` header, so `deck gateway sync` will target the right Workspace even without the `--workspace` flag.

## {{site.konnect_short_name}} Workspace limitations

{% include_cached /gateway/konnect-workspaces-limitations.md %}

## Route collisions

When you create or modify a Route, {{site.konnect_short_name}} checks it against Routes in every Workspace on the control plane, including the `default` one.
If it overlaps with an existing Route on path, method, host, and SNI, the request is rejected with a `409` naming the collision.
This catches the cross-team conflicts that can come up when several teams share a data plane.

This is deliberately simpler than the on-prem behavior.
On-prem {{site.base_gateway}} defaults to a configurable "smart" strategy that also reasons about path patterns and regexes.
Configurable strategies for {{site.konnect_short_name}} Workspaces are planned for a later phase.
In practice, the deterministic check covers the same conflicts for plain-text Routes.
If you rely on regex-Route collision detection on-prem, reach out to your account team.
