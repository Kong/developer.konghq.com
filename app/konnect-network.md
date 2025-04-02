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
faqs:
  - q: What types of data travel between the {{site.konnect_saas}} control plane and the data plane nodes, and how?
    a: |
      Two types of data travel between planes using secure TCP port `443`:
      * **Configuration** – The control plane sends config data to the data plane nodes.
      * **Telemetry** – Data plane nodes send usage data to the control plane for Analytics and billing.

      Telemetry includes traffic metrics by service, route, and consuming application. It does not include any customer data. 
      All telemetry is encrypted using mTLS.
  - q: How frequently do data planes send telemetry data to the control plane?
    a: |
      Telemetry data is sent at different intervals depending on the data plane version:
      * **2.x** – Every 10 seconds by default
      * **3.x** – Every 1 second by default

      You can customize this interval using the [`analytics_flush_interval`](/gateway/configuration/#analytics-flush-interval) setting.
  - q: How long can data plane nodes remain disconnected from the control plane?
    a: |
      Data plane nodes continue pinging the control plane until reconnected or stopped. 
      They use cached config and function normally, unless:
      * The license expires
      * The cached config file (`config.json.gz` or `dbless.lmdb`) is deleted
  - q: What happens if the control plane and data plane nodes disconnect?
    a: |
      Data plane nodes use the cached configuration until they can reconnect. 
      Once reconnected, the control plane sends the latest configuration. 
      It does not queue or replay any older configuration changes.

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


The following [geographic regions](/konnect-geos/) and their hostname region identifiers are supported:
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

If you use [Mesh Manager](/mesh-manager/) to manage your Kong service mesh, you must add the `{geo}.mesh.sync.konghq.com:443` hostname to your firewall allowlist. The geo can be `au`, `eu`, `us`, or `global`.