---
title: "{{site.base_gateway}} Control Plane and Data Plane communication"
content_type: reference
layout: reference

products:
    - gateway

works_on:
   - on-prem
   - konnect

min_version:
    gateway: '3.5'

description: Learn how Control Planes communicate with Data Planes and how you can secure them.

related_resources:
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxying/
  - text: "{{site.base_gateway}} network"
    url: /gateway/network/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/

faqs:
  - q: What types of data travel between the {{site.konnect_saas}} Control Plane and the Data Plane nodes, and how?
    a: |
      There are two types of data that travel between the planes: configuration
      and telemetry. Both use the secure TCP port `443`.

      * **Configuration:** The Control Plane sends configuration data to any connected
        Data Plane node in the cluster.

      * **Telemetry:** Data plane nodes send usage information to the Control Plane
        for Analytics and for account billing. Analytics tracks aggregate traffic by
        Gateway Service, Route, and the consuming application. For billing, {{site.base_gateway}} tracks the
        number of Gateway Services, API calls, and active dev portals.

      Telemetry data does not include any customer information or any data processed
      by the Data Plane. All telemetry data is encrypted using mTLS.
  - q: How frequently does configuration data travel between the {{site.konnect_short_name}} Control Plane and Data Plane nodes?
    a: When you make a configuration change on the Control Plane, that change is immediately pushed to any connected Data Plane nodes.
  - q: How frequently do Data Planes send telemetry data to the Control Plane?
    a: |
      Data planes send messages every 1 second by default. You can configure this interval using the [`analytics_flush_interval`](/gateway/configuration/#analytics-flush-interval) setting.
  - q: What happens if {{site.konnect_saas}} goes down?
    a: |
      If the {{site.base_gateway}}-hosted Control Plane goes down, the Control Plane/Data Plane
      connection gets interrupted. You can't access the Control Plane or
      change any configuration during this time.

      A connection interruption has no negative effect on the function of your
      Data Plane nodes. They continue to proxy and route traffic normally. 
      For more information, see [Control Plane outage management](/gateway/cp-outage/).
  - q: What happens if the Control Plane and Data Plane nodes disconnect?
    a: |
      If a Data Plane node becomes disconnected from its Control Plane, configuration can't
      travel between them. In that situation, the Data Plane node continues to use cached
      configuration until it reconnects to the Control Plane and receives new
      configuration.

      Whenever a connection is re-established with the Control Plane, it pushes the latest 
      configuration to the Data Plane node. It doesn't queue up or try to apply older changes.

      If your Control Plane is a {{site.mesh_product_name}} global Control Plane, see {{site.mesh_product_name}} failure modes for connectivity issues.
  - q: If the Data Plane loses communication with the Control Plane, what happens to telemetry data?
    a: |
      If a Data Plane loses contact with the Control Plane, the Data Plane accumulates request data into a buffer.
      Once the buffer fills up, the Data Plane starts dropping older data. 
      The faster your requests come in, the faster the buffer fills up.

      By default, the buffer limit is 100000 requests. You can configure a custom buffer amount using the 
      [`analytics_buffer_size_limit`](/gateway/configuration/#analytics-buffer-size-limit) setting.
  - q: How long can Data Plane nodes remain disconnected from the Control Plane?
    a: |
      A Data Plane node will keep pinging the
      Control Plane, until the connection is re-established or the Data Plane node
      is stopped.

      The Data Plane node needs to connect to the Control Plane at least once.
      The Control Plane pushes configuration to the Data Plane, and each Data Plane
      node caches that configuration in-memory. It continues to use this cached
      configuration until it receives new instructions from the Control Plane.

      There are situations that can cause further problems:
      * If the license that the Data Plane node received from the Control Plane expires,
      the node stops working.
      * If the Data Plane node's configuration cache file (`config.json.gz`) or directory (`dbless.lmdb`)
      gets deleted, it loses access to the last known configuration and starts
      up empty.
  - q: Can I restart a Data Plane node if the Control Plane is down or disconnected?
    a: Yes. If you restart a Data Plane node, it uses a cached configuration to continue functioning the same as before the restart.
  - q: Can I create a new Data Plane node when the connection is down?
    a: Yes. {{site.base_gateway}} can support configuring new Data Plane nodes in the event of a Control Plane outage. For more information, see [Control Plane outage management](/gateway/cp-outage/). 
  - q: Can I create a backup configuration to use in case the cache fails?
    a: You can set the [`declarative_config`](/gateway/configuration/#declarative-config) option to load a fallback YAML config.
  - q: Can I change a Data Plane node's configuration when it's disconnected from the Control Plane?
    a: |
      Yes, if necessary, though any manual configuration will be overwritten the next
      time the Control Plane connects to the node.

      You can load configuration manually in one of the following ways:
      * Copy the configuration cache file (`config.json.gz`) or directory (`dbless.lmdb`) from another data
      plane node with a working connection and overwrite the cache file on disk
      for the disconnected node.
      * Remove the cache file, then start the Data Plane node with
      [`declarative_config`](/gateway/configuration/#declarative-config)
      to load a fallback YAML config.

tags:
  - control-plane
  - data-plane

breadcrumbs:
  - /gateway/
---


When {{site.base_gateway}} deployments run either in either [managed](/dedicated-cloud-gateways/) or [hybrid mode](/gateway/hybrid-mode/), there is
a separate Control Plane attached to a Data Plane consisting of one or more Data Plane nodes.
Data traveling between Control Planes and Data Planes is secured through a
mutual TLS handshake.
Data Plane nodes initiate the connection to the {{site.base_gateway}} Control Plane.
Once the connection is established, the Control Plane can send configuration data to the 
connected Data Plane nodes.
Normally, each Data Plane node maintains a persistent connection with the Control
Plane. 
The node sends a heartbeat to the Control Plane every 30 seconds to
keep the connection alive. 
If it doesn't receive an answer, it tries to reconnect to the Control Plane after a 5-10 second delay. If communication is interrupted and either side can't send or receive config, Data Plane nodes can still continue proxying traffic to clients. 

Whenever a Data Plane node receives new configuration from the Control Plane,
it immediately loads that config into memory. 
At the same time, it caches the config to the file system.
By default, Data Plane nodes store their configuration in an unencrypted LMDB database directory, `dbless.lmdb`, in {{site.base_gateway}}’s [`prefix` path](/gateway/configuration/#prefix).

## Data Plane node start sequence

When operating as a Data Plane (DP) node, {{site.base_gateway}} loads configuration in the following order:

1. **Local config cache**: If the `dbless.lmdb` file exists in the [`kong_prefix`](/gateway/configuration/#prefix) directory (default: `/usr/local/kong`), the Data Plane node uses it as its configuration.
2. **Declarative config file**: If the cache is missing and `declarative_config` is set, the node loads the specified file.
3. **No configuration**: If neither the cache nor a declarative config file is available, the node starts with an empty configuration and returns 404 for all requests.
4. **Contact control plane**: In all cases, the Data Plane node attempts to fetch the latest configuration from the Control Plane. If successful, the configuration is saved to the local cache (`dbless.lmdb`).

## Secure Control Plane and Data Plane communications

{{site.base_gateway}} Control Planes support Data Plane authentication using either a pinned certificate or a certificate signed by a certificate authority (CA).

- **Pinned certificates**: Data Planes authenticate using a shared certificate. Both the Control Plane and Data Plane nodes are provisioned with the same certificate. The Control Plane verifies that the Data Plane connected using the pinned certificate.

- **Public Key Infrastructure (PKI) certificates**: Data Planes authenticate using certificates signed by a CA. The Control Plane must be provisioned with the CA certificate to verify the trust chain. If intermediate certificates are involved, Data Plane nodes must include them when connecting to the Control Plane.

### Certificate chain 
You must upload enough of the certificate chain in the Control Plane so that the Control Plane can trust the certificate in the Data Plane request and authenticate.

Consider the following scenarios with this example cert chain:

{% table %}
columns:
  - title: Certificate
    key: certificate
  - title: Type
    key: type
  - title: Issuer
    key: issuer
rows:
  - certificate: "`cert1`"
    type: Service
    issuer: Issued by Intermediary
  - certificate: "`cert2`"
    type: Intermediary
    issuer: Issued by Root
  - certificate: "`cert3`"
    type: Root
    issuer: Issued by Root (Self-signed)
{% endtable %}


* **Upload only `cert1` to the Control Plane**: This is the pinned certificate. You can include just `cert1` in your Data Plane request and not include the chain. The Control Plane doesn’t need to evaluate the issuer because it trusts the cert itself.
* **Upload only `cert2` to the Control Plane**: This would mean any cert coming in that has (issuer: intermediary) would be trusted. You can include just `cert1` in your Data Plane request. The Control Plane would trust any certificate issued by the intermediary public key. 
* **Upload only `cert3` to the Control Plane**: This is the typical PKI case. It means any cert signed by the root is trusted. However, since `cert1` is signed by an intermediary and `cert2` is signed by root, you need to include both `cert1` and `cert2` in your Data Plane request. The Control Plane would trust the whole chain because `cert2` is issued by `cert3` and `cert1` is issued by `cert2`.

## Generate certificates in {{site.konnect_short_name}} 
{{site.konnect_short_name}} provides several options to generate or add a certificate for your Data Plane nodes. 

### Generate a certificate key pair

When you use the {{site.konnect_short_name}} wizard to create a Data Plane node, it generates a certificate key pair. Data Planes can establish a connection with this certificate key pair (pinned cert).

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the {{site.konnect_short_name}} sidebar.
1. Click the control plane you want to create a data plane node for.
1. Navigate to **Data Plane Nodes** in the sidebar.
1. Click **New Data Plane Node**. 
1. Follow the instructions in the wizard to create a data plane node and generate the certificate key pair.
1. Click **Done**.

### Generate a CA-signed certificate

Using the {{site.konnect_short_name}} UI, you can generate a CA certificate, which allows Data Planes to connect using a certificate signed by that CA (PKI). Alternatively you can upload your own CA using the upload option.

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the {{site.konnect_short_name}} sidebar.
1. Click the control plane you want to create a data plane node for.
1. From the Action menu, select **Data Plane Certificates**. 
1. Either upload or generate a certificate.

### Renew a certificate in {{site.konnect_short_name}}

Certificates generated by {{site.konnect_short_name}} are valid for 10 years. If you bring your own certificates, make sure to review the expiration date and associated metadata. 

If you originally created your Data Plane node container using one of the
Docker options in {{site.konnect_short_name}}, we recommend creating a new Data Plane node with renewed
certificates.

1. Stop the Data Plane node container.
2. Navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/), select a Control Plane, open **Data Plane Nodes** from the side menu, and click **New Data Plane Node**.
3. Run the script to create a new Data Plane node with
updated certificates.
4. Remove the old Data Plane node container.

If your Data Plane nodes are running on Linux or Kubernetes, or if you have a
Docker container that was _not_ created using the quick setup script, you must
generate new certificates and replace them on the existing nodes. For more information, see the [Data Plane reference](/gateway-manager/data-plane-reference/).

## Generate a certificate/key pair in {{site.base_gateway}} on-prem

In hybrid mode, a mutual TLS handshake (mTLS) is used for authentication so the
actual private key is never transferred on the network, and communication
between Control Plane and Data Plane nodes is secure.

Before using hybrid mode, you need a certificate/key pair.
{{site.base_gateway}} provides two modes for handling certificate/key pairs:

* **Shared mode:** (Default) Use the {{site.base_gateway}} CLI to generate a certificate/key
pair, then distribute copies across nodes. The certificate/key pair is shared
by both Control Plane and Data Plane nodes.
* **PKI mode:** Provide certificates signed by a central certificate authority
(CA). {{site.base_gateway}} validates both sides by checking if they are from the same CA. This
eliminates the risks associated with transporting private keys.

{:.warning}
> **Warning:** If you have a TLS-aware proxy between the Data Plane and Control Plane nodes, you
must use PKI mode and set [`cluster_server_name`](/gateway/configuration/#cluster-server-name) to the Control Plane hostname in
`kong.conf`. Do not use shared mode, as it uses a non-standard value for TLS server name
indication, and this will confuse TLS-aware proxies that rely on SNI to route
traffic.

### Shared mode

{:.warning}
> **Warning:** Protect the private key. Ensure the private key file can only be accessed by {{site.base_gateway}} nodes that belong to the cluster. If the key is compromised, you must regenerate and replace certificates and keys on all Control Plane and Data Plane nodes.

1. On an existing {{site.base_gateway}} instance, create a certificate/key pair:
    ```bash
    kong hybrid gen_cert
    ```
    This will generate `cluster.crt` and `cluster.key` files and save them to
    the current directory. By default, the certificate/key pair is valid for three
    years, but can be adjusted with the `--days` option. See `kong hybrid --help`
    for more usage information.

2. Copy the `cluster.crt` and `cluster.key` files to the same directory
on all {{site.base_gateway}} Control Plane and Data Plane nodes; e.g., `/cluster/cluster`.
  Set appropriate permissions on the key file so it can only be read by {{site.base_gateway}}.

### PKI mode

With PKI mode, the Hybrid cluster can use certificates signed by a central
certificate authority (CA).

In this mode, the Control Plane and Data Plane don't need to use the same
[`cluster_cert`](/gateway/configuration/#cluster-cert) and [`cluster_cert_key`](/gateway/configuration/#cluster-cert-key). Instead, {{site.base_gateway}} validates both sides by
checking if they are from the same CA. Certificates on the Control Plane and Data Plane must contain the `TLS Web Server Authentication` and `TLS Web Client Authentication` as X509v3 Extended Key Usage extension, respectively.

{{site.base_gateway}} doesn't validate the CommonName (CN) in the Data Plane certificate, it can take an arbitrary value.


## Use a forward proxy to secure communication across a firewall

If your Control Plane and Data Planes are separated by a firewall that routes external communications through a proxy, you can configure {{site.base_gateway}} to authenticate with the proxy server and allow traffic to pass through.

To use a forward proxy for Control Plane and Data Plane communication, you need to configure the following parameters in [`kong.conf`](/gateway/manage-kong-conf/):

{% navtabs "http-protocol-example" %}
{% navtab "HTTP example" %}
```
proxy_server = 'http://USERNAME:PASSWORD@PROXY_HOST:PROXY_PORT'
proxy_server_ssl_verify = off
cluster_use_proxy = on
```
{% endnavtab %}
{% navtab "HTTPS example" %}
```
proxy_server = 'https://USERNAME:PASSWORD@PROXY_HOST:PROXY_PORT'
proxy_server_ssl_verify = on
cluster_use_proxy = on
lua_ssl_trusted_certificate = system  # or the full certificate or path to cert file
```
{% endnavtab %}
{% endnavtabs %}

[Reload {{site.base_gateway}}](/how-to/restart-kong-gateway-container/) for the connection to take effect.

The following table explains what each forward proxy parameter does:

<!--vale off-->
{% kong_config_table %}
config:
  - name: proxy_server
  - name: proxy_server_ssl_verify
  - name: cluster_use_proxy
  - name: lua_ssl_trusted_certificate
{% endkong_config_table %}
<!--vale on-->

