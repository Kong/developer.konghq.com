---
title: KIC high availability

description: |
  How to run multiple {{ site.kic_product_name }} instances with leader election
content_type: reference
layout: reference

products:
  - kic
breadcrumbs: 
  - /kubernetes-ingress-controller/
works_on:
  - on-prem
  - konnect

---

{{ site.kic_product_name }} reads state from the Kubernetes API server and generates a {{ site.base_gateway }} configuration. If {{ site.kic_product_name }} isn't running, new {{ site.base_gateway }} instances won't receive a configuration. Existing {{ site.base_gateway }} instances will continue to process traffic using their existing configuration.

When a {{ site.kic_product_name }} instance is offline, it's a major issue. The configuration loaded by {{ site.base_gateway }} will quickly become outdated, especially the upstream endpoints hosting your applications. Without {{ site.kic_product_name }} running, {{ site.base_gateway }} won't detect new application pods or remove old pods from it's routing configuration.

## Leader election

Kong recommends running at least _two_ {{ site.kic_product_name }} instances. {{site.kic_product_name}} elects a _leader_ when connected to a database-backed cluster or when Gateway Discovery is configured. This ensures that only a single controller pushes configuration to {{site.base_gateway}}'s database or to {{site.base_gateway}}'s Admin API to avoid potential conflicts and race conditions.

When a leader controller shuts down, other instances will detect that there is no longer a leader, and one will promote itself to the leader.

Leader election is controlled using the `Lease` resource. For this reason, {{ site.kic_product_name }} needs permission to create a `Lease` resource. By default, the permission is given at the Namespace level.

The name of the Lease is derived from the value of the `election-id` CLI flag or `CONTROLLER_ELECTION_ID` environment variable (default: `5b374a9e.konghq.com`) and `election-namespace` (default: `""`) as: "$ELECTION_ID-$ELECTION_NAMESPACE". 

The {{ site.kic_product_name }} Helm chart sets a custom value of `kong-ingress-controller-leader` for `CONTROLLER_ELECTION_ID`. If the {{site.kic_product_name}} was deployed using Helm, the default `Lease` that is used for leader election is named `kong-ingress-controller-leader-kong`, and it will be present in the same namespace that the controller is deployed in.