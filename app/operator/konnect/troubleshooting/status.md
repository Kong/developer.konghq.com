---
title: "Status Fields"
description: "How do I find out why my resources aren't being reconciled against {{ site.konnect_short_name }}?"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

---

## Status fields

Each Kubernetes resource that is mapped to a Konnect entity has several fields that indicate its status in Konnect.

### Konnect native objects

Objects that are native to {{site.konnect_short_name}} - they exist only in {{site.konnect_short_name}} - have the following `status` fields:

- `id` is the unique identifier of the Konnect entity as assigned by {{site.konnect_product_name}} API. If it's unset (empty string), it means the {{site.konnect_product_name}} entity hasn't been created yet.
- `serverURL` is the URL of the {{site.konnect_product_name}} server in which the entity exists.
- `organizationID` is ID of {{site.konnect_product_name}} Org that this entity has been created in.

You can observe these fields by running:

```bash
kubectl get <resource> <resource-name> -o yaml | yq '.status'
```

You should see the following output:

```yaml
conditions:
  ...
id: 7dcf6756-b2e7-4067-a19b-111111111111
organizationID: 5ca26716-02f7-4430-9117-111111111111
serverURL: https://us.api.konghq.com
```

These objects are defined under `konnect.konghq.com` API group.

### Objects configuring {{site.base_gateway}}

Some objects can be used to configure {{site.base_gateway}} and are not native to {{site.konnect_short_name}}.  These are for example `KongConsumer`, `KongService`, `KongRoute` and `KongPlugin`. They are defined under `configuration.konghq.com` API group.

They can also be used in other contexts like for instance: be used for reconciliation with {{site.kic_product_name}}.

These objects have their {{site.konnect_short_name}} status related fields nested under `konnect` field. These fields are:

- `controlPlaneID` is the ID of the Control Plane this entity is associated with.
- `id` is the unique identifier of the Konnect entity as assigned by {{site.konnect_product_name}} API. If it's unset (empty string), it means the {{site.konnect_product_name}} entity hasn't been created yet.
- `serverURL` is the URL of the {{site.konnect_product_name}} server in which the entity exists.
- `organizationID` is ID of {{site.konnect_product_name}} Org that this entity has been created in.

You can observe these fields by running:

```bash
kubectl get <resource> <resource-name> -o yaml | yq '.status.konnect'
```

You should see the following output:

```yaml
controlPlaneID: 7dcf6756-b2e7-4067-a19b-111111111111
id: 7dcf6756-b2e7-4067-a19b-111111111111
organizationID: 5ca26716-02f7-4430-9117-111111111111
serverURL: https://us.api.konghq.com
```