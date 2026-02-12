---
title: "{{site.mesh_product_name}} data collection"
description: Enable or disable data collection in {{site.mesh_product_name}}. Understand what telemetry is collected and how to configure reporting.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: '{{site.mesh_product_name}} resource sizing guidelines'
    url: '/mesh/resource-sizing-guidelines/'
  - text: '{{site.mesh_product_name}} version compatibility'
    url: '/mesh/version-compatibility/'
  - text: Audit logs
    url: /mesh/access-audit/

tags:
    - security
---

{{site.mesh_product_name}} can collect information about your deployment to continuously improve the product and gather anonymous feedback. 
The collected data is sent to Kong servers securely for storage and aggregation.

You can use the following environment variable to enable data collection when installing the control plane in Kubernetes, or before running `kuma-cp` in Universal mode: 

```sh
KUMA_REPORTS_ENABLED=true
```

You can also set the `reports.enabled` field to `true` in the YAML configuration file.

For more information, see the [control plane configuration docs](/mesh/control-plane-configuration/).

## What data is collected

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: desc
rows:
  - field: "`version`"
    desc: The installed version of {{site.mesh_product_name}} you're running.
  - field: "`product`"
    desc: The static value "{{site.mesh_product_name}}".
  - field: "`unique_id`"
    desc: The control plane hostname followed by a random UUID generated each time the control plane instance is restarted.
  - field: "`backend`"
    desc: "The storage mode for your configuration: in-memory, etcd, or Postgres."
  - field: "`mode`"
    desc: "The control plane mode: zone or global."
  - field: "`hostname`"
    desc: The hostname of each {{site.mesh_product_name}} control plane deploy.
  - field: "`signal`"
    desc: "A `start` signal sent when the control plane starts, followed by a `ping` once each hour."
  - field: "`cluster_id`"
    desc: Unique identifier for the entire {{site.mesh_product_name}} cluster. The value is the same for all control planes in the cluster.
  - field: "`dps_total`"
    desc: The total number of data plane proxies across all meshes.
  - field: "`meshes_total`"
    desc: The total number of meshes deployed.
  - field: "`zones_total`"
    desc: The total number of zones deployed.
  - field: "`internal_services`"
    desc: The total number of services running inside your meshes.
  - field: "`external_services`"
    desc: The total number of external services configured for your meshes.
  - field: "`services_total`"
    desc: The total number of services in your mesh network.
{% endtable %}
