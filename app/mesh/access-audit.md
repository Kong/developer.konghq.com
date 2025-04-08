---
title: "Access Audit"
description: "Track all user and system actions in {{site.mesh_product_name}} using the AccessAudit resource and configurable backends"
content_type: reference
layout: reference
products:
    - gateway

tags:
  - regions
  - geos
  - network

works_on:
  - on-prem

related_resources:
  - text: "Mesh"
    url: /mesh/overview/
---
Access Audit allows you to track all actions executed in {{site.mesh_product_name}}, including actions performed by users and by the Control Plane.

## AccessAudit Resource

The `AccessAudit` resource defines which actions and resource types should be audited. It is global-scoped, meaning it applies across all meshes.

{% navtabs "resource"%}
{% navtab "Universal" %}
```yaml
type: AccessAudit
name: audit-1
rules:
- types: ["TrafficPermission", "TrafficRoute", "Mesh"] # list of types which should be audited. If empty, then default types are audited (see "Default types" below).
  mesh: default # Mesh within which access to resources is granted. It can only be used with the Mesh-scoped resources and Mesh itself. If empty, resources from all meshes will be audited.
  access: ["CREATE", "UPDATE", "DELETE"] # an action that is bound to a type.
  accessAll: true # an equivalent of specifying all possible accesses. Either access or access all can be specified.
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
  - types: ["TrafficPermission", "TrafficRoute", "Mesh"] # list of types which should be audited. If empty, then all resources will be audited.
    mesh: default # Mesh within which access to resources is granted. It can only be used with the Mesh-scoped resources and Mesh itself. If empty, resources from all meshes will be audited.
    access: ["CREATE", "UPDATE", "DELETE"] # an action that is bound to a type.
    accessAll: true # an equivalent of specifying all possible accesses. Either access or access all can be specified.
```
{% endnavtab %} 
{% endnavtabs %} 
## Default Behavior
If `types` is not specified in an `AccessAudit` rule, all types are audited except those defined in the Control Plane config under `kmesh.access.audit.skipDefaultTypes`. These excluded types include status and insight resources that are managed solely by the Control Plane.


#### Other actions

Aside `CREATE`, `UPDATE`, `DELETE`, `AccessAudit` lets you audit all actions that are controllable with RBAC:
* `GENERATE_DATAPLANE_TOKEN` (you can use `mesh` to audit only tokens generated for specific mesh)
* `GENERATE_USER_TOKEN`
* `GENERATE_ZONE_CP_TOKEN`
* `GENERATE_ZONE_TOKEN`
* `VIEW_CONFIG_DUMP`
* `VIEW_STATS`
* `VIEW_CLUSTERS`



## Backends

The backend is external storage that persists audit logs. Currently, there is one available backend which is a JSON file.

### JSON file

The JSON file is a backend that persists audit logs to a single file in JSON format.
You can configure the file backend with the Control Plane config.
It can only be configured using YAML config, not environment variables.

```yaml
kmesh:
  access:
    audit:
      # Types that are skipped by default when `types` list in AccessAudit resource is empty
      skipDefaultTypes: ["DataplaneInsight", "ZoneIngressInsight", "ZoneEgressInsight", "ZoneInsight", "ServiceInsight", "MeshInsight"]
      backends:
      - type: file
        file:
          # Path to the file that will be filled with logs
          path: /tmp/audit.logs
          rotation:
            # If true, rotation is enabled.
            # Example: if we set path to /tmp/audit.log then after the file is rotated we will have /tmp/audit-2021-06-07T09-15-18.265.log
            enabled: true
            # Maximum number of the old log files to retain
            maxRetainedFiles: 10
            # Maximum size in megabytes of a log file before it gets rotated
            maxSizeMb: 100
            # Maximum number of days to retain old log files based on the timestamp encoded in their filename
            maxAgeDays: 30
```

## Multi-zone

In a multi-zone setup, `AccessAudit` is not synchronized between the global Control Plane and the zone Control Plane.