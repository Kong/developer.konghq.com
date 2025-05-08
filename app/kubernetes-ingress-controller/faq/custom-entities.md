---
title: Configuring Custom Entities

description: |
  How do I configure Custom Entities such as `degraphql_routes` using KIC?

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: FAQs

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---

{{ site.kic_product_name }} provides an interface to configure {{ site.base_gateway }} entities using CRDs.

Some {{ site.base_gateway }} plugins define custom entities that require configuration. These entities can be configured using the [`KongCustomEntity` resource](/kubernetes-ingress-controller/reference/custom-resources/#kongcustomentity).

The `KongCustomEntity` resource contains a `type` field which indicates the type of Kong entity to create, and a `fields` property which can contain any values that need to be set on an entity.

In the following example, a `degraphql_routes` entity is created with two properties, `uri` and `query`.

```yaml
spec:
  type: degraphql_routes
  fields:
    uri: "/contacts"
    query: "query{ contacts { name } }"
```

This corresponds to the `uri` and `query` parameters documented in the [DeGraphQL plugin documentation](/plugins/degraphql/).

## Troubleshooting

Each `KongCustomEntity` is validated against the schema from Kong.  If the configuration is invalid, an `Event` with the reason set to `KongConfigurationTranslationFailed` will be emitted.  The `involvedObject` of this `Event` will be set to the `KongCustomEntity` resource.

For more information on observability with events, see our [events guide](/kubernetes-ingress-controller/observability/events/).