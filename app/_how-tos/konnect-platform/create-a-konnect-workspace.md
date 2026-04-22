---
title: Create a Workspace in {{site.konnect_short_name}}
permalink: /how-to/create-a-konnect-workspace/
content_type: how_to
description: Learn how to create a {{site.konnect_short_name}} Workspace.
tools:
  - ui
  - konnect-api
beta: true
products:
    - konnect

works_on:
    - konnect
tags:
  - rbac
entities:
  - workspace

related_resources:
  - text: "Workspaces reference"
    url: /gateway/entities/workspace/
tldr:
    q: How do I create a Workspace in {{site.konnect_short_name}}?
    a: |
        Create a control plane group with a control plane. Send a PUT request to the `/control-planes/{controlPlaneGroupId}/group-settings` endpoint with `workspaceable` set to `true` and the ID of the control plane you want to apply the Workspace to.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.14'
---



Follow these steps to configure a workspace-enabled CPG:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. From the **New** dropdown menu, select **New control plane group**.
1. In the **Name** field, enter `Workspace control plane group`.
1. From the **Control Planes** dropdown menu, select `quickstart`.
1. Click **Save**.

From your control plane group overview, export the following environment variables:

```sh
export CPG_ID="YOUR CONTROL PLANE GROUP ID"
export CP_ID="YOUR QUICKSTART CONTROL PLANE ID"
```


1. Enable Workspaces on the CPG: Use httpie to send a PUT request to the Kong Konnect API to enable the workspaceable flag and set the default Control Plane.

curl -X PUT "https://us.api.konghq.com/v2/control-planes/$CPG_ID/group-settings" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "workspaceable": true,
    "default_workspace_member_id": "'"$CP_ID"'"
  }'

Add any additional member Control Planes to the CPG you created in step 2.

## How it works

The default_workspace_member_id parameter specifies which Control Plane within the CPG will act as the default for any workspace-related operations. This Control Plane will operate and can be treated in the same manner as the 'default' workspace in Kong Enterprise. It is where entities should be created if specific workspace is required.
