---
title: Licenses
content_type: reference
entities:
  - license

description: A {{site.base_gateway}} license object lets you manage Enterprise licenses.

tier: enterprise

tools:
  - admin-api
  - konnect-api
  - kic
  - deck
  - terraform

api_specs:
  - gateway/admin-ee

schema:
  api: gateway/admin-ee
  path: /schemas/License

---

@todo

A license entity lets you configure a license in your {{site.base_gateway}} cluster, in both traditional and hybrid mode deployments. In hybrid mode deployments, the control plane sends licenses configured through the `/licenses` endpoint to all data planes in the cluster. The data planes use the most recent `updated_at` license.