---
title: "Networking in {{site.konnect_short_name}}"
description: 'Learn about Control Plane and Data Plane networking information like ports, hostnames, and communication in {{site.konnect_short_name}}.'
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
  - text: " {{site.base_gateway}} Control Plane and Data Plane communication"
    url: /gateway/cp-dp-communication/

faqs:
  - q: What types of data travel between the {{site.konnect_short_name}} Control Plane and the Data Plane nodes, and how?
    a: |
      Two types of data travel between planes using secure TCP port `443`:
      * **Configuration** – The Control Plane sends config data to the Data Plane nodes.
      * **Telemetry** – Data plane nodes send usage data to the Control Plane for Analytics and billing.

      Telemetry includes traffic metrics by Service, Route, and consuming application. It does not include any customer data.
      All telemetry is encrypted using mTLS.

      If you use [Debugger](/observability/debugger/), {{site.konnect_short_name}} will collect request and response data. {{site.konnect_short_name}} only collects this data if you've opted in to Debugger, it doesn't collect this data by default.
  - q: How frequently do Data Planes send telemetry data to the Control Plane?
    a: |
      Telemetry data is sent at different intervals depending on the Data Plane version:
      * **2.x** – Every 10 seconds by default
      * **3.x** – Every 1 second by default

      You can customize this interval using the [`analytics_flush_interval`](/gateway/configuration/#analytics-flush-interval) setting.
  - q: How long can Data Plane nodes remain disconnected from the Control Plane?
    a: |
      Data plane nodes continue pinging the Control Plane until reconnected or stopped.
      They use cached config and function normally, unless:
      * The license expires
      * The cached config file (`config.json.gz` or `dbless.lmdb`) is deleted
  - q: Where is configuration cached on Data Plane nodes?
    a: |
      When a Data Plane node receives new configuration from the Control Plane, it immediately loads it into memory and also caches it to disk.
      The cache location depends on the Gateway version:

      * **2.x Gateway** – Configuration is stored in an unencrypted cache file, `config.json.gz`, located in the {{site.base_gateway}} prefix path.
      * **3.x Gateway** – Configuration is stored in an unencrypted LMDB database directory, `dbless.lmdb`, also in the {{site.base_gateway}} prefix path.
  - q: What happens if the Control Plane and Data Plane nodes disconnect?
    a: |
      Data plane nodes use the cached configuration until they can reconnect.
      Once reconnected, the Control Plane sends the latest configuration.
      It does not queue or replay any older configuration changes.
  - q: Can I restart a Data Plane node if the Control Plane is down or disconnected?
    a: |
      Yes. Restarting a Data Plane node will load its cached configuration and resume normal function.
  - q: Can I change a Data Plane node's configuration when it's disconnected from the Control Plane?
    a: |
      Yes:
      * Copy the configuration cache file or directory from a working node
      * Remove the cache and use [`declarative_config`](/gateway/configuration/#declarative-config)
  - q: If the Data Plane loses communication with the Control Plane, what happens to telemetry data?
    a: |
      The Data Plane buffers request data locally. If the buffer fills up (default: 100000 requests), older data is dropped.
      You can configure the buffer size using the [`analytics_buffer_size_limit`](/gateway/configuration/#analytics-buffer-size-limit) setting.
  - q: How do the Control Plane and Data Plane communicate?
    a: |
      Data traveling between Control Planes and Data Planes is secured through a mutual TLS handshake.
      Data plane nodes initiate the connection to the {{site.konnect_short_name}} Control Plane.
      Once the connection is established, the Control Plane can send configuration data to the connected Data Plane nodes.

      Each Data Plane node maintains a persistent connection with the Control Plane and sends a heartbeat every 30 seconds.
      If the Control Plane doesn't respond, the Data Plane node attempts to reconnect after a 5–10 second delay.
  - q: What IP addresses are associated with {{site.konnect_short_name}} regional hostnames?
    a: Visit [https://ip-addresses.origin.konghq.com/ip-addresses.json](https://ip-addresses.origin.konghq.com/ip-addresses.json) for the list of IPs associated to regional hostnames. You can also subscribe to [https://ip-addresses.origin.konghq.com/rss](https://ip-addresses.origin.konghq.com/rss) for updates.

---

{{site.konnect_short_name}} deployments run either in either [managed](/dedicated-cloud-gateways/) or [Hybrid Mode](/gateway/hybrid-mode), which means that there is a separate Control Plane attached to a Data Plane consisting of one or more Data Plane nodes. {{site.konnect_short_name}} Control Planes and Data Plane nodes rely on specific ports and hostnames for secure communication and configuration.
The following tables detail the required ports for cluster communication, audit logging, and the hostnames for connecting to regional Control Plane and telemetry endpoints.

## Control plane ports

The {{site.konnect_short_name}} Control Plane uses the following ports:

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
      Cluster communication port for configuration and telemetry data. The {{site.konnect_short_name}} Control Plane uses this port to listen for connections and to communicate with Data Plane nodes.<br>
      The cluster communication port must be accessible to Data Plane nodes within the same cluster. This port is protected by mTLS to ensure end-to-end security and integrity.
  - port: "`8071`<br>`20010`"
    protocol: "TCP<br>UDP"
    description: "Ports used for audit logging."
{% endtable %}


{{site.base_gateway}}'s hosted Control Plane expects traffic on these ports, so they can't be customized.

{:.info}
> **Note**: If you can't make outbound connections using port `443`, you can use an existing proxy in your network to make the connection. See [Use a forward proxy to secure communication across a firewall](/gateway/cp-dp-communication/#use-a-forward-proxy-to-secure-communication-across-a-firewall) for details.

## Data plane node ports


{% include_cached /sections/data-plane-node-ports.md %}


## Hostnames


The following [geographic regions](/konnect-platform/geos/) and their hostname region identifiers are supported:
* AU (Australia): `au`
* EU (Europe): `eu`
* ME (Middle East): `me`
* IN (India): `in`
* SG (Singapore) (beta): `sg`
* US (United States): `us`

Depending on the regions your organization uses, you'll need to allowlist the hostnames and include the region-specific identifier in the hostname in place of `{region}`:

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
  - hostname: "`REGION.api.konghq.com`"
    description: The {{site.konnect_short_name}} API for the geo. Necessary if you are using decK in your workflow, decK uses this API to access and apply configurations.
  - hostname: "`PORTAL_ID.REGION.kongportals.com`"
    description: The URL for the Dev Portal in the geo.
  - hostname: "`CONTROL_PLANE_DNS_PREFIX.REGION.cp.konghq.com`"
    description: Handles configuration for a Control Plane in the geo. Data plane nodes connect to this host to receive configuration updates. This hostname is unique to each organization and Control Plane.
  - hostname: "`CONTROL_PLANE_DNS_PREFIX.REGION.tp.konghq.com`"
    description: Gathers telemetry data for a Control Plane in the geo. This hostname is unique to each organization and Control Plane.
{% endtable %}
<!--vale on-->

{:.warning}
> **Important:** Visit [https://ip-addresses.origin.konghq.com/ip-addresses.json](https://ip-addresses.origin.konghq.com/ip-addresses.json) for a full list of regional and service ingress IPs. The `ingressIPs` section contains a list of all ingress IPs per geo and consolidated IPs per service. To avoid coupling firewall rules to specific services or DNS suffixes (such as `cp`, `tp`), we recommend allowlisting the values in the `ingressIPs` block for each region. This ensures your setup is more resilient to future infrastructure or DNS changes. You can also subscribe to [https://ip-addresses.origin.konghq.com/rss](https://ip-addresses.origin.konghq.com/rss) for updates.

## Mesh hostnames in {{site.konnect_short_name}}

If you use {{site.konnect_short_name}} to manage your service mesh, you must add the `{geo}.mesh.sync.konghq.com:443` hostname to your firewall allowlist. The geo can be `au`, `eu`, `us`, or `global`.

## Specify IP addresses that can connect to {{site.konnect_short_name}}

Org Admins can specify an IP address or a range of IP addresses that are allowed to connect to {{site.konnect_short_name}} through its supported interfaces. This includes the UI, the {{site.konnect_short_name}} [APIs](/konnect-api/), the [Admin AP](/admin-api/), [decK](/decK/), and [Terraform](/terraform/).

This IP allow list applies to all {{site.konnect_short_name}} communication that goes through the Admin API.

{:.warning}
> **Important:** 
* If the source IP address you have allow-listed is no longer reachable and IP allow list enforcement is enabled, access to {{site.konnect_short_name}} will be blocked.
> * If you're configuring IP allow list for the first time, it takes effect immediately. If you're editing existing IP allow list values, the changes will take effect after five minutes.

To configure IP allow list for {{site.konnect_short_name}}, send a PATCH request to the `/source-ip-restriction` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/source-ip-restriction
status_code: 201
method: PATCH
body:
    enabled: true
    allowed_ips:
    - 192.168.1.1
    - 192.168.1.0/22
{% endkonnect_api_request %}
<!--vale on-->

