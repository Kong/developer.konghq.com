---
title: "Networking in {{site.konnect_short_name}}"
description: 'Learn about control plane and data plane networking information like ports, hostnames, and communication in {{site.konnect_short_name}}.'
content_type: reference
breadcrumbs:
  - /konnect/
layout: reference
products:
  - konnect
works_on:
  - konnect
related_resources:
  - text: "{{site.base_gateway}} ports"
    url: /gateway/network-ports-firewall/
  - text: Networking in {{site.base_gateway}}
    url: /gateway/network/
  - text: "{{site.base_gateway}} control plane and data plane communication"
    url: /gateway/cp-dp-communication/

faqs:
  - q: What types of data travel between the {{site.konnect_short_name}} control plane and the data plane nodes, and how?
    a: |
      Two types of data travel between planes using secure TCP port `443`:
      * **Configuration**: The control plane sends config data to the data plane nodes.
      * **Telemetry**: Data plane nodes send usage data to the control plane for Analytics and billing.

      Telemetry includes traffic metrics by Service, Route, and consuming application. It does not include any customer data.
      All telemetry is encrypted using mTLS.

      If you use [Debugger](/observability/debugger/), {{site.konnect_short_name}} will collect request and response data. {{site.konnect_short_name}} only collects this data if you've opted in to Debugger, it doesn't collect this data by default.
  - q: How frequently do data planes send telemetry data to the control plane?
    a: |
      Telemetry data is sent at different intervals depending on the data plane version:
      * **2.x**: Every 10 seconds by default
      * **3.x**: Every 1 second by default

      You can customize this interval using the [`analytics_flush_interval`](/gateway/configuration/#analytics-flush-interval) setting.
  - q: How long can data plane nodes remain disconnected from the control plane?
    a: |
      Data plane nodes continue pinging the control plane until reconnected or stopped.
      They use cached config and function normally, unless:
      * The license expires
      * The cached config file (`config.json.gz` or `dbless.lmdb`) is deleted
  - q: Where is configuration cached on data plane nodes?
    a: |
      When a data plane node receives new configuration from the control plane, it immediately loads it into memory and also caches it to disk.
      The cache location depends on the Gateway version:

      * **2.x Gateway**: The data plane node stores the configuration in an unencrypted cache file, `config.json.gz`, in the {{site.base_gateway}} prefix path.
      * **3.x Gateway**: The data plane node stores the configuration in an unencrypted LMDB database directory, `dbless.lmdb`, also in the {{site.base_gateway}} prefix path.
  - q: What happens if the control plane and data plane nodes disconnect?
    a: |
      Data plane nodes use the cached configuration until they can reconnect.
      Once reconnected, the control plane sends the latest configuration.
      The control plane does not queue or replay any older configuration changes.
  - q: Can I restart a data plane node if the control plane is down or disconnected?
    a: |
      Yes. Restarting a data plane node will load its cached configuration and resume normal function.
  - q: Can I change a data plane node's configuration when it's disconnected from the control plane?
    a: |
      Yes:
      * Copy the configuration cache file or directory from a working node
      * Remove the cache and use [`declarative_config`](/gateway/configuration/#declarative-config)
  - q: If the data plane loses communication with the control plane, what happens to telemetry data?
    a: |
      The data plane buffers request data locally. If the buffer fills up (default: 100000 requests), older data is dropped.
      You can configure the buffer size using the [`analytics_buffer_size_limit`](/gateway/configuration/#analytics-buffer-size-limit) setting.
  - q: How do the control plane and data plane communicate?
    a: |
      Data traveling between control planes and data planes is secured through a mutual TLS handshake.
      Data plane nodes initiate the connection to the {{site.konnect_short_name}} control plane.
      Once the connection is established, the control plane can send configuration data to the connected data plane nodes.

      Each data plane node maintains a persistent connection with the control plane and sends a heartbeat every 30 seconds.
      If the control plane doesn't respond, the data plane node attempts to reconnect after a 5–10 second delay.
  - q: What IP addresses are associated with {{site.konnect_short_name}} regional hostnames?
    a: Visit [https://ip-addresses.origin.konghq.com/ip-addresses.json](https://ip-addresses.origin.konghq.com/ip-addresses.json) for the list of IPs associated to regional hostnames. You can also subscribe to [https://ip-addresses.origin.konghq.com/rss](https://ip-addresses.origin.konghq.com/rss) for updates.

---

{{site.konnect_short_name}} deployments run in either [managed](/dedicated-cloud-gateways/) or [Hybrid Mode](/gateway/hybrid-mode/), which means there is a separate control plane attached to a data plane consisting of one or more data plane nodes.
{{site.konnect_short_name}} control planes and data plane nodes rely on specific ports and hostnames for secure communication and configuration.
The following tables detail the required ports for cluster communication, audit logging, and the hostnames for connecting to regional control plane and telemetry endpoints.

## Control plane ports

The {{site.konnect_short_name}} control plane uses the following ports:

{% table %}
columns:
  - title: Port
    key: port
  - title: Protocol
    key: protocol
  - title: Description
    key: description
rows:
  - port: "`443`"
    protocol: "TCP<br>HTTPS"
    description: >-
      Cluster communication port for configuration and telemetry data. The {{site.konnect_short_name}} control plane uses this port to listen for connections and to communicate with data plane nodes.<br>
      The cluster communication port must be accessible to data plane nodes within the same cluster. This port is protected by mTLS to ensure end-to-end security and integrity.
  - port: "`8071`<br>`20010`"
    protocol: "TCP<br>UDP"
    description: "Ports used for audit logging."
{% endtable %}

{{site.base_gateway}}'s hosted control plane expects traffic on these ports, so they can't be customized.

{:.info}
> **Note**: If you can't make outbound connections using port `443`, you can use an existing proxy in your network to make the connection. See [Use a forward proxy to secure communication across a firewall](/gateway/cp-dp-communication/#use-a-forward-proxy-to-secure-communication-across-a-firewall) for details.

## Data plane node ports

{% include_cached /sections/data-plane-node-ports.md %}

## Hostnames

Depending on the regions your organization uses, you'll need to allowlist specific hostnames.
Replace `REGION` with the region identifier for your geo.
The specific hostnames depend on your runtime or application.

The following [geographic regions](/konnect-platform/geos/) and their hostname region identifiers are supported:
* AU (Australia): `au`
* EU (Europe): `eu`
* ME (Middle East): `me`
* IN (India): `in`
* SG (Singapore) (beta): `sg`
* US (United States): `us`

{:.warning}
> **Important:** Visit [https://ip-addresses.origin.konghq.com/ip-addresses.json](https://ip-addresses.origin.konghq.com/ip-addresses.json) for a full list of regional and service ingress IPs. The `ingressIPs` section contains a list of all ingress IPs per geo and consolidated IPs per service. 
> <br><br>
> To avoid coupling firewall rules to specific services or DNS suffixes (such as `cp`, `tp`), we recommend allowlisting the values in the `ingressIPs` block for each region. 
> This ensures your setup is more resilient to future infrastructure or DNS changes. You can also subscribe to [https://ip-addresses.origin.konghq.com/rss](https://ip-addresses.origin.konghq.com/rss) for updates.

### Shared hostnames

Allowlist the following hostnames for any runtime or application:

<!--vale off-->
{% table %}
columns:
  - title: Hostname
    key: hostname
  - title: Description
    key: description
rows:
  - hostname: "`cloud.konghq.com`"
    description: The {{site.konnect_short_name}} platform.
  - hostname: "`global.api.konghq.com`"
    description: The {{site.konnect_short_name}} API for platform authentication, identity, permissions, teams, and organizational entitlements and settings.
{% endtable %}

### API Gateway hostnames in {{site.konnect_short_name}}

In addition to the [shared hostnames](#shared-hostnames), add the following {{site.base_gateway}} hostnames to your firewall allow list:
<!--vale off-->
{% table %}
columns:
  - title: Hostname
    key: hostname
  - title: Description
    key: description
rows:
  - hostname: "`REGION.api.konghq.com`"
    description: The {{site.konnect_short_name}} API for the geo. Required if you use decK, which uses this API to access and apply configurations.
  - hostname: "`CONTROL_PLANE_DNS_PREFIX.REGION.cp.konghq.com`"
    description: Handles configuration for a {{site.base_gateway}} control plane in the geo. Data plane nodes connect to this host to receive configuration updates. This hostname is unique to each organization and control plane.
  - hostname: "`CONTROL_PLANE_DNS_PREFIX.REGION.tp.konghq.com`"
    description: Gathers telemetry data for a {{site.base_gateway}} control plane in the geo. This hostname is unique to each organization and control plane.
{% endtable %}
<!--vale on-->

### {{site.event_gateway_short}} hostnames in {{site.konnect_short_name}}

In addition to the [shared hostnames](#shared-hostnames), add the following {{site.event_gateway_short}} hostnames to your firewall allow list:
<!--vale off-->
{% table %}
columns:
  - title: Hostname
    key: hostname
  - title: Description
    key: description
rows:
  - hostname: "`REGION.control-plane.konghq.com`"
    description: Handles configuration for a {{site.event_gateway_short}} control plane in the geo. Data plane nodes connect to this host to receive configuration updates.
  - hostname: "`REGION.telemetry.konghq.com`"
    description: Gathers telemetry data for a {{site.event_gateway_short}} control plane in the geo.
{% endtable %}
<!--vale on-->

### Mesh hostnames in {{site.konnect_short_name}}

In addition to the [shared hostnames](#shared-hostnames), add the following {{site.mesh_product_name}} hostnames to your firewall allow list:

<!--vale off-->
{% table %}
columns:
  - title: Hostname
    key: hostname
  - title: Description
    key: description
rows:
  - hostname: "`REGION.mesh.sync.konghq.com`"
    description: The URL for the Mesh runtime in the geo.
{% endtable %}
<!--vale on-->

### {{site.konnect_short_name}} application hostnames

In addition to the [shared hostnames](#shared-hostnames), add the following {{site.konnect_short_name}} application hostnames to your firewall allow list:

<!--vale off-->
{% table %}
columns:
  - title: Hostname
    key: hostname
  - title: Description
    key: description
rows:
  - hostname: "`REGION.identity.konghq.com`"
    description: The URL for the Identity server in the geo.
  - hostname: "`PORTAL_ID.REGION.kongportals.com`"
    description: The URL for the Dev Portal in the geo.
{% endtable %}
<!--vale on-->

## Specify IP addresses that can connect to {{site.konnect_short_name}}

Org Admins can specify an IP address or a range of IP addresses that are allowed to connect to {{site.konnect_short_name}} through its supported interfaces. This includes the UI, the {{site.konnect_short_name}} [APIs](/konnect-api/), the [Admin API](/admin-api/), [decK](/decK/), [kongctl](/kongctl/), and [Terraform](/terraform/).

This IP allow list applies to all {{site.konnect_short_name}} communication that goes through the Admin API.

{:.warning}
> **Important:**
> * If the source IP address you have allow-listed is no longer reachable and IP allow list enforcement is enabled, access to {{site.konnect_short_name}} will be blocked.
> * If you're configuring IP allow list for the first time, it takes effect immediately. If you're editing existing IP allow list values, the changes will take effect after five minutes.

To configure IP allow list for {{site.konnect_short_name}}, send a PUT request to the `/organizations/$ORG_ID/ip-allow-list` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/organizations/$ORG_ID/ip-allow-list
status_code: 201
region: global
method: PUT
body:
    enabled: true
    allowed_ips:
    - 192.168.1.1
    - 192.168.1.0/22
{% endkonnect_api_request %}
<!--vale on-->

You can also configure allowed IPs for your Dev Portals. For more information, see [Specify IP addresses that can connect to your Dev Portal](/dev-portal/security-settings/#specify-ip-addresses-that-can-connect-to-your-dev-portal).

