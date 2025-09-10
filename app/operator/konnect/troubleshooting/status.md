---
title: "Status Fields"
description: "How do I find out why my resources aren't being reconciled against {{ site.konnect_short_name }}?"
content_type: reference
layout: reference
search_aliases:
  - KGO status fields
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

---

## Status fields

Each Kubernetes resource that is mapped to a {{site.konnect_short_name}} entity has several fields that indicate its status in Konnect.

### {{site.konnect_short_name}} native objects

Objects that are native to {{site.konnect_short_name}},they exist only in {{site.konnect_short_name}} - have the following `status` fields:

- `id` is the unique identifier of the Konnect entity as assigned by {{site.konnect_short_name}} API. If it's unset (empty string), it means the {{site.konnect_short_name}} entity hasn't been created yet.
- `serverURL` is the URL of the {{site.konnect_short_name}} server in which the entity exists.
- `organizationID` is the ID of {{site.konnect_short_name}} Org that this entity has been created in.

To inspect these fields:

```bash
kubectl get <resource> <resource-name> -o yaml | yq '.status'
```

Example output:

```yaml
conditions:
  ...
id: 7dcf6756-b2e7-4067-a19b-111111111111
organizationID: 5ca26716-02f7-4430-9117-111111111111
serverURL: https://us.api.konghq.com
```

These objects are defined under the `konnect.konghq.com` API group.

### {{ site.base_gateway }} configuration objects

Resources like `KongConsumer`, `KongService`, `KongRoute`, and `KongPlugin` configure {{ site.base_gateway }} and are **not** native to {{ site.konnect_short_name }}. These are defined under the `configuration.konghq.com` API group and may be used with other controllers, such as {{ site.kic_product_name }}.

When managed by {{ site.gateway_operator_product_name }} for {{ site.konnect_short_name }}, Konnect-specific status fields appear under `.status.konnect`:

- `controlPlaneID`: The ID of the associated Konnect Control Plane.
- `id`: The unique ID assigned by the {{ site.konnect_short_name }} API. If empty, the entity hasn't been created.
- `serverURL`: The URL of the {{ site.konnect_short_name }} server where the entity resides.
- `organizationID`: The Org ID under which the entity was created.

To inspect these fields:


```bash
kubectl get <resource> <resource-name> -o yaml | yq '.status.konnect'
```

Example output:

```yaml
controlPlaneID: 7dcf6756-b2e7-4067-a19b-111111111111
id: 7dcf6756-b2e7-4067-a19b-111111111111
organizationID: 5ca26716-02f7-4430-9117-111111111111
serverURL: https://us.api.konghq.com
```
