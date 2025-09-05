---
title: "{{site.mesh_product_name}} audit logs"
description: "Track all user and system actions in {{site.mesh_product_name}} using the AccessAudit resource and configurable backends"
content_type: reference
layout: reference
products:
    - mesh
breadcrumbs:
  - /mesh/

tags:
  - geos
  - network
  - logging

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Observability
    url: /mesh/observability/
  - text: Role-based access control
    url: /mesh/rbac/
---
Access auditing allows you to track all actions executed in {{site.mesh_product_name}}, including actions performed by users and by the Control Plane.

## AccessAudit resource

The `AccessAudit` resource defines which actions and resource types should be audited. It is global-scoped, meaning it applies across all meshes.

{% navtabs "resource"%}
{% navtab "Universal" %}
```yaml
type: AccessAudit
name: audit-1
rules:
- types: ["TrafficPermission", "TrafficRoute", "Mesh"] 
  mesh: default 
  access: ["CREATE", "UPDATE", "DELETE"] 
  accessAll: true 
```
{% endnavtab %} 
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: AccessAudit
metadata:
  name: role-1
spec:
  rules:
  - types: ["TrafficPermission", "TrafficRoute", "Mesh"]
    mesh: default
    access: ["CREATE", "UPDATE", "DELETE"]
    accessAll: true
```
{% endnavtab %} 
{% endnavtabs %} 

The following table describes the different parameters you can set when configuring audit logs:
<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: item
  - title: Description
    key: description
rows:
  - item: "`types`"
    description: List of types which should be audited. If empty, then all resources will be audited.
  - item: "`mesh`"
    description: |
      Mesh within which access to resources is granted. 
      It can only be used with the Mesh-scoped resources and Mesh itself. 
      If empty, resources from all meshes will be audited.
  - item: "`access`"
    description: An action that is bound to a type.
  - item: "`accessAll`"
    description: |
      Equivalent to specifying all possible accesses. 
      Either access or access all can be specified.{% endtable %}
<!--vale on-->

## Default behavior
If `types` is not specified in an `AccessAudit` rule, all types are audited except those defined in the Control Plane config under `kmesh.access.audit.skipDefaultTypes`. These excluded types include status and insight resources that are managed solely by the Control Plane.


#### Additional audit log actions

Aside from `CREATE`, `UPDATE`, `DELETE`, `AccessAudit` also lets you audit all actions that are controllable with RBAC:
* `GENERATE_DATAPLANE_TOKEN` (you can use `mesh` to audit only tokens generated for specific mesh)
* `GENERATE_USER_TOKEN`
* `GENERATE_ZONE_CP_TOKEN`
* `GENERATE_ZONE_TOKEN`
* `VIEW_CONFIG_DUMP`
* `VIEW_STATS`
* `VIEW_CLUSTERS`



## Audit log backends

The backend is external storage that persists audit logs. There is one available backend: a JSON file.

### JSON file

The JSON file is a backend that persists audit logs to a single file in JSON format.
You can configure the file backend with the Control Plane config.

{:.info}
> The file backend can only be configured using YAML config, not environment variables.

```yaml
kmesh:
  access:
    audit:
      skipDefaultTypes: ["DataplaneInsight", "ZoneIngressInsight", "ZoneEgressInsight", "ZoneInsight", "ServiceInsight", "MeshInsight"]
      backends:
      - type: file
        file:
          path: /tmp/audit.logs
          rotation:
            enabled: true
            maxRetainedFiles: 10
            maxSizeMb: 100
            maxAgeDays: 30
```

The following table describes the different parameters you can set when configuring the audit log backend:

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: item
  - title: Description
    key: description
rows:
  - item: "`skipDefaultTypes`"
    description: "Types that are skipped by default when `types` list in AccessAudit resource is empty."
  - item: "`file.path`"
    description: Path to the file that will be filled with logs.
  - item: "`file.rotation.enabled`"
    description: |
      If true, rotation is enabled.
      For example: If you set the path to `/tmp/audit.log`, then after the file is rotated, you will have `/tmp/audit-2021-06-07T09-15-18.265.log`.
  - item: "`file.rotation.maxRetainedFiles`"
    description: Maximum number of the old log files to retain.
  - item: "`file.rotation.maxSizeMb`"
    description: Maximum size in megabytes of a log file before it gets rotated.
  - item: "`file.rotation.maxAgeDays`"
    description: Maximum number of days to retain old log files based on the timestamp encoded in their filename.{% endtable %}
<!--vale on-->

## AccessAudit in multi-zone deployments

In a [multi-zone](/mesh/mesh-multizone-service-deployment/) setup, `AccessAudit` is not synchronized between the global Control Plane and the zone Control Plane.