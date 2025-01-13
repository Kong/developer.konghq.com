---
title: Licenses
content_type: reference
entities:
  - license

description: A {{site.base_gateway}} License entity allows you manage Enterprise licenses.

tier: enterprise

tools:
  - admin-api

api_specs:
  - gateway/admin-ee

schema:
  api: gateway/admin-ee
  path: /schemas/License

---

@todo

<!--content outline:
What
order of precedence of license config
topologies table, explain how KG passes the license (how it works)
how long is it good for? Expiration
how to get one
how to deploy/update one (links to how tos)
link to /gateway/enterprise-vs-oss/
link to deployment topologies LP
link to license report
link to License LP (?)
-->

## What is a License?

A License entity allows you configure a license in your {{site.base_gateway}} cluster, in both [traditional and hybrid mode deployments](/gateway/deployment-topologies/). {{site.base_gateway}} can be used with or without a license. To use [Enterprise features](/gateway/enterprise-vs-oss/), {{site.base_gateway}} enforces the presence and validity of a {{site.konnect_product_name}} license file.

You will receive this file from Kong when you sign up for a
{{site.konnect_product_name}} Enterprise subscription. [Contact Kong](https://konghq.com/get-started) for more information. If you have purchased a subscription but haven’t received a license file, contact your sales representative.

## How it works
In hybrid mode deployments, the control plane sends licenses configured through the `/licenses` endpoint to all data planes in the cluster. The data planes use the most recent `updated_at` license.

## Deploy a license

## Expiration

how long it's good for
updating license

## License report?

## Schema

{% entity_schema %}

## Set up a License

{% entity_example %}
type: license
data:
  payload: "{\"license\":{\"payload\":{\"admin_seats\":\"1\",\"customer\":\"Example Company, Inc\",\"dataplanes\":\"1\",\"license_creation_date\":\"2017-07-20\",\"license_expiration_date\":\"2017-07-20\",\"license_key\":\"00141000017ODj3AAG_a1V41000004wT0OEAU\",\"product_subscription\":\"Konnect Enterprise\",\"support_plan\":\"None\"},\"signature\":\"6985968131533a967fcc721244a979948b1066967f1e9cd65dbd8eeabe060fc32d894a2945f5e4a03c1cd2198c74e058ac63d28b045c2f1fcec95877bd790e1b\",\"version\":\"1\"}}"
{% endentity_example %}