---
title: "{{site.konnect_short_name}} ports and network requirments"
description: 'See which ports and hostnames {{site.konnect_short_name}} uses.'
content_type: reference
layout: reference
products:
    - gateway
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
| `443`    | TCP <br>HTTPS | Cluster communication port for configuration and telemetry data. The {{site.konnect_saas}} control plane uses this port to listen for connections and communicate with data plane nodes. <br> The cluster communication port must be accessible to data plane nodes within the same cluster. This port is protected by mTLS to ensure end-to-end security and integrity. |
| `8071`   | TCP <br> UDP | Port used for audit logging. |

{{site.base_gateway}}'s hosted control plane expects traffic on these ports, so they can't be customized. 

{:.info}
> **Note**: If you can't make outbound connections using port `443`, you can use an existing proxy in your network to make the connection. See [Use a forward proxy to secure communication across a firewall](/gateway/cp-dp-communication/#use-a-forward-proxy-to-secure-communication-across-a-firewall) for details. 

## Data plane node ports

{{site.base_gateway}} uses data plane node ports to proxy communication.

{% include_cached /sections/data-plane-node-ports.md %}

For Kubernetes or Docker deployments, map ports as needed. For example, if you
want to use port `3001` for the proxy, map `3001:8000`.

## Hostnames

Data plane nodes initiate the connection to the {{site.konnect_short_name}} control plane.
They require access through firewalls to communicate with the control plane. To let a data plane node request and receive configuration, and send telemetry data, add the applicable hostnames in this section to the firewall allowlist.

{{site.kic_product_name}} also uses these hostnames to initiate the connection to the {{site.konnect_short_name}} [Control Planes Configuration API](/konnect/api/control-plane-configuration/latest/) to:

* Synchronize the configuration of the {{site.base_gateway}} instances with {{site.konnect_short_name}}
* Register data plane nodes
* Fetch license information

Data plane nodes initiate the connection to {{site.konnect_short_name}} APIs to report Analytics data.

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

If you plan to use [Mesh Manager](/konnect/mesh-manager/) to manage your Kong service mesh, you must add the `{geo}.mesh.sync.konghq.com:443` hostname to your firewall allowlist. The geo can be `au`, `eu`, `us`, or `global`.