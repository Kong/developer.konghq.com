---
title: "Using Workspaces"

description: |
  Learn how to use KIC to sync resources to a specific {{site.base_gateway}} Workspace. Deploy multiple namespaces and use the --watch-namespace flag with a Workspace.
breadcrumbs:
  - /kubernetes-ingress-controller/
content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---


{{ site.kic_product_name }} can manage configuration in multiple [Workspaces](/gateway/entities/workspace/) when running in [DB-backed mode](/kubernetes-ingress-controller/deployment-topologies/db-backed/). Each Workspace needs a different {{ site.kic_product_name }} instance with the `--watch-namespace` and `--kong-workspace` flags set.

* `--watch-namespace`: Namespace(s) to watch for Kubernetes resources. Defaults to all namespaces. To watch multiple namespaces, use a comma-separated list of namespaces.
* `--kong-workspace`: {{site.base_gateway}} Workspace to configure. Leave this empty if not using Kong Workspaces.

Use this `values.yaml` when you install {{ site.kic_product_name }} using Helm to configure the namespace and Workspace:

```yaml
gateway:
  ingressController:
    env:
      watch_namespace: mynamespacehere
      kong_workspace: workspacename
```

{{ site.kic_product_name }} watches for resources in the defined namespace and send them to the configured Workspace. This allows teams to manage their own resources in Kubernetes and send them to their own Workspace within {{ site.base_gateway }}.