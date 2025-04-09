---
title: "Custom Plugins in Dedicated Cloud Gateways"
description: "Use the {{site.konnect_short_name}} Control Plane to distribute and manage custom Lua plugins across all Dedicated Cloud Gateways."
content_type: reference
layout: reference
products:
  - gateway
tags:
  - dedicated-gateways
  - plugins
works_on:
  - konnect
faqs:
  - q: How do I manage custom plugins after uploading them?
    a: |
      Once uploaded, you can manage custom plugins using any of the following methods:

      * [decK](/deck/)
      * [Control Plane Config API](/api/konnect/control-planes-config/v2/)
      * [{{site.konnect_short_name}} UI](https://cloud.konghq.com/)

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Azure Peering
    url: /dedicated-cloud-gateways/azure-peering/
---

With Dedicated Cloud Gateways, {{site.konnect_short_name}} can stream custom plugins from the Control Plane to the Data Plane.

The Control Plane becomes the single source of truth for plugin versions. You only need to upload the plugin once, and {{site.konnect_short_name}} handles distribution to all Data Planes in the same Control Plane.

A [custom plugin](/custom-plugins/) that meets the following requirements:

* Unique name per plugin
* One `handler.lua` and one `schema.lua` file
* Cannot run in the `init_worker` phase or create timers
* Must be written in Lua
* A [personal or system access token](https://cloud.konghq.com/global/account/tokens) for the {{site.konnect_short_name}} API

## How do I add a custom plugin?

You can use the following request with [jq](https://jqlang.org/) as a template for adding a custom plugin: 


```sh
curl -X POST https://{region}.api.konghq.com/v2/control-planes/{control-plane-id}/core-entities/custom-plugins \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {your-access-token}" \
  -d "$(jq -n \
      --arg handler "$(cat handler.lua)" \
      --arg schema "$(cat schema.lua)" \
      '{"handler":$handler,"name":"streaming-headers","schema":$schema}')" \
    | jq
```
You can also upload plugins using the Plugins menu in the [{{site.konnect_short_name}} UI](https://cloud.konghq.com/gateway-manager/).
headers:

