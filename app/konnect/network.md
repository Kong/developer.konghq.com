---
title: "{{site.konnect_short_name}} ports and network requirements"
description: 'See which ports and hostnames {{site.konnect_short_name}} uses.'
content_type: reference
layout: reference
products:
    - gateway
works_on:
  - konnect
tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform
related_resources:
  - text: "{{site.base_gateway}} ports"
    url: /gateway/network-ports-firewall/
  - text: Networking in {{site.base_gateway}}
    url: /gateway/network/
  - text: " {{site.base_gateway}} control plane and data plane communication"
    url: /gateway/cp-dp-communication/
---

{{site.konnect_short_name}} control planes and data plane nodes rely on specific ports and hostnames for secure communication and configuration. The following tables detail the required ports for cluster communication, audit logging, and the hostnames for connecting to regional control plane and telemetry endpoints.

## Control plane ports

The {{site.konnect_short_name}} control plane uses the following ports:

| Port      | Protocol  | Description |
|:----------|:----------|:------------|
| `443`    | TCP <br>HTTPS | Cluster communication port for configuration and telemetry data. The {{site.konnect_saas}} control plane uses this port to listen for connections and to communicate with data plane nodes. <br> The cluster communication port must be accessible to data plane nodes within the same cluster. This port is protected by mTLS to ensure end-to-end security and integrity. |
| `8071`   | TCP <br> UDP | Port used for audit logging. |

{{site.base_gateway}}'s hosted control plane expects traffic on these ports, so they can't be customized. 

{:.info}
> **Note**: If you can't make outbound connections using port `443`, you can use an existing proxy in your network to make the connection. See [Use a forward proxy to secure communication across a firewall](/gateway/cp-dp-communication/#use-a-forward-proxy-to-secure-communication-across-a-firewall) for details. 

## Data plane node ports


{% include_cached /sections/data-plane-node-ports.md %}


## Hostnames


The following [geographic regions](/konnect/geos/) and their hostname region identifiers are supported:
* AU (Australia): `au`
* EU (Europe): `eu`
* ME (Middle East): `me`
* IN (India): `in`
* US (United States): `us`

Depending on the regions your organization uses, you'll need to allowlist the hostnames and include the region-specific identifier in the hostname in place of `{region}`:

| Hostname      | Description |
|----------|----------|
| `cloud.konghq.com`    | The {{site.konnect_short_name}} platform. |
| `global.api.konghq.com` | The {{site.konnect_short_name}} API for platform authentication, identity, permissions, teams, and organizational entitlements and settings. |
| `{region}.api.konghq.com` | The {{site.konnect_short_name}} API for the geo. Necessary if you are using decK in your workflow, decK uses this API to access and apply configurations. |
| `PORTAL_ID.{region}.portal.konghq.com` | The URL for the Dev Portal in the geo. |
| `CONTROL_PLANE_DNS_PREFIX.{region}.cp0.konghq.com` | Handles configuration for a control plane in the geo. Data plane nodes connect to this host to receive configuration updates. This hostname is unique to each organization and control plane. |
| `CONTROL_PLANE_DNS_PREFIX.{region}.tp0.konghq.com` | Gathers telemetry data for a control plane in the geo. This hostname is unique to each organization and control plane. |

## Mesh Manager hostnames

If you use [Mesh Manager](/konnect/mesh-manager/) to manage your Kong service mesh, you must add the `{geo}.mesh.sync.konghq.com:443` hostname to your firewall allowlist. The geo can be `au`, `eu`, `us`, or `global`.