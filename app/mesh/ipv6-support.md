---
title: IPv6 support
description: Learn how to enable or disable IPv6 support in {{site.mesh_product_name}}.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
related_resources:
  - text: Data plane proxy
    url: /mesh/data-plane-proxy/
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: Zone ingress
    url: /mesh/zone-ingress/
---

All {{site.mesh_product_name}} entities support mixed IPv4/IPv6 environments and IPv6-only setups. This includes global and zone control planes, data plane proxies, iptables scripts, and the CNI. Most IPv6 configurations work without additional setup. However, when data plane proxies run in an IPv6-only environment, configure the DNS to generate IPv6 addresses by setting `KUMA_DNS_SERVER_CIDR` to an IPv6 CIDR block that does not overlap with any existing network in your environment.

## Disabling IPv6

In some cases you might not want to use IPv6 at all. You can disable it with the following parameters:
* On Kubernetes, set:
    * The config option `{{site.set_flag_values_prefix}}runtime.kubernetes.injector.sidecarContainer.ipFamilyMode=ipv4` or the environment variable `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_IP_FAMILY_MODE=ipv4` to disable IPv6 for all workloads.
    * The annotation `kuma.io/transparent-proxying-ip-family-mode: ipv4` on a Pod to disable IPv6 for that specific Pod.
* On Universal, set `networking.transparentProxying.ipFamilyMode=IPv4` on your `Dataplane` resource.