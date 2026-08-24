---
title: "{{site.konnect_product_name}}: Uploading a custom plugin schema to a Konnect Ingress Controller Control Plane"
content_type: support
description: Currently the only way to do this is via the Konnect Admin API as the KIC Control Plane GUI is read-only.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "Kong Konnect: How do I upload a custom plugin schema to a Konnect Ingress Controller Control Plane?"
  a: |
    The Konnect Ingress Controller Control Plane GUI is read-only, so upload a custom plugin schema through the Konnect Admin API's plugin-schemas endpoint instead. If the plugin is written in a language other than Lua, convert its schema to Lua first, since that's the only format Konnect accepts.
related_resources:
  - text: "Konnect API reference: create-plugin-schemas"
    url: /api/konnect/control-planes-config/v2/#/Custom%20Plugin%20Schemas/create-plugin-schemas
---

## Problem

When I use a standard Hybrid Control Plane in Konnect, I have the ability to upload my custom plugin schema in the GUI. This functionality appears to not be available when I am using a {{site.kic_product_name}} Control Plane. How do I upload my `schema.lua` file to a Konnect Ingress Controller Control Plane?

## Solution

Currently the only way to do this is via the Konnect Admin API as the KIC Control Plane GUI is read-only. In the future this may change for a better user experience.

Here is a sample POST request to achieve this:

```bash

curl --request POST \
  --url https://us.api.konghq.com/v2/control-planes/<control_plane_uuid>/core-entities/plugin-schemas \
  --header 'Authorization: Bearer <kpat_token>' \
  --header 'Content-Type: application/json' \
  --data '{
  "lua_schema": "return {\n  name = \"py-hello\",\n  fields = {\n    { config = {\n        type = \"record\",\n        fields = {\n          { message = { type = \"string\", required = true } }\n        },\n      },\n    },\n  },\n}"
}
'
```

Additional considerations:

If your custom plugin is coded in a language other than LUA (GO, Python, etc), you will need to convert your schema file to LUA for it to be accepted by Konnect
