---
title: Manage Workspaces in Konnect
content_type: how_to
beta: true
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
---

A [Workspace](/gateway/entities/workspace/) is a namespace for Gateway entities inside a {{site.konnect_short_name}} control plane. Entities in one Workspace are invisible to and independent of entities in another. Data planes attach to the parent control plane and serve traffic across all of its Workspaces.

Every control plane has a `default` Workspace. Any entities created before additional Workspaces are added live there, as well as any CA certificates. For example, a plugin in the `default` Workspace applies only to entities in the `default` Workspace, not across all Workspaces.

## Features and limitations

### Private beta features

The following features and settings are available in the Workspaces private beta:

- Create and manage Workspaces through the {{site.konnect_short_name}} API, the {{site.konnect_short_name}} UI, and decK.
- Duplicate entity names across Workspaces (for example, the same consumer `username` in two Workspaces with different credentials).
- Route collision detection across all Workspaces, including the default one.
- decK compatibility (use 1.60 or later), including `--workspace` and `--all-workspaces`.

### Private beta limitations

The following are limitations of the private beta, but will be implemented for the GA release:

- **Workspace-scoped permissions and roles.** A Control Plane Admin role on the parent control plane is required to manage any Workspace; there's no per-Workspace role. 
- **Sharing entities across Workspaces**, including a plugin configured once on the parent control plane that applies to all of its Workspaces. In this phase a plugin lives in one Workspace and applies only there.
- **Workspace-level analytics.** 
- **Configurable Route collision strategies.** The behavior described in [Route collisions](#route-collisions) is fixed in this phase. 
- **Terraform provider support for Workspaces.** 

### {{site.konnect_short_name}} Workspace limitations

The following are {{site.konnect_short_name}} Workspace limitations:

- A Workspace-enabled control plane cannot be part of a Control Plane Group.
- Workspaces are not supported on serverless control planes.
- [Route collision](#route-collisions) detection uses exact match, not the "smart" strategy available on-prem.

## Create a Workspace

Export your control plane ID:

```sh
export CONTROL_PLANE_ID='YOUR-CONTROL-PLANE-ID'
```

List existing Workspaces on the control plane:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/workspaces
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

Create a new Workspace:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/workspaces
status_code: 201
method: POST
body:
    name: team-payments
{% endkonnect_api_request %}
<!--vale on-->

You can reference a Workspace by name or by ID in any subsequent API path.

## Manage entities in a Workspace

Export the Workspace name:

```sh
export WORKSPACE='team-payments'
```

Create a Gateway Service in the Workspace:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/$WORKSPACE/services
status_code: 201
method: POST
body:
    name: payment-api
    url: http://payment-service.internal:8080
{% endkonnect_api_request %}
<!--vale on-->

Export the Service ID from the response:

```sh
export SERVICE_ID='YOUR-SERVICE-ID'
```

Create a Route in the Workspace, referencing the Service:

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

{:.info}
> Entities in the `default` Workspace use the existing un-prefixed path, for example `.../core-entities/services`.

## Custom plugins

Install custom plugin schemas at the control plane level (in the `default` Workspace). Once installed, you can create plugin instances of that custom plugin in any Workspace on the control plane, the same way you would with a bundled plugin.

```sh
# schema lives in default
curl -X POST .../core-entities/custom-plugins ...

# instance can live in any workspace
curl -X POST .../core-entities/$WORKSPACE/plugins \
  -d '{ "name": "my-custom-plugin", "config": { ... } }'
```

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

```sh
# Dump one Workspace
deck gateway dump --konnect-control-plane-name quickstart --workspace team-payments -o team-payments.yaml

# Dump every workspace into separate files
deck gateway dump --konnect-control-plane-name quickstart --all-workspaces

# Apply a config file into a Workspace
deck gateway sync team-payments.yaml --konnect-control-plane-name quickstart --workspace team-payments
```

A dumped file carries a `_workspace:` header, so `deck gateway sync` will target the right Workspace even without the `--workspace` flag.

## Route collisions

When you create or modify a Route, {{site.konnect_short_name}} checks it against Routes in every Workspace on the control plane, including the `default` one. If it overlaps with an existing Route on path, method, host, and SNI, the request is rejected with a `400` naming the collision. This catches the cross-team conflicts that may be introduced when several teams share a data plane.

This is deliberately simpler than the on-prem behavior. On-prem {{site.base_gateway}} defaults to a configurable "smart" strategy that also reasons about path patterns and regexes. Configurable strategies for {{site.konnect_short_name}} Workspaces are planned for a later phase. In practice, the deterministic check covers the same conflicts for plain-text Routes. If you rely on regex-Route collision detection on-prem, reach out to your account team.
