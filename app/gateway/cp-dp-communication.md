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

description: placeholder

related_resources:
  - text: Proxying with {{site.base_gateway}}
    url: /gateway/traffic-control/proxying/
  - text: "{{site.base_gateway}} network"
    url: /gateway/network/

faqs:
  - q: How does network peering work with Dedicated Cloud Gateway nodes?
    a: Each Cloud Gateway node is part of a dedicated Cloud Gateway network that corresponds to a specific cloud region, such as `us-east-1` or `us-west-2`. For enhanced security and seamless connectivity between your cloud network and the {{site.konnect_short_name}} environment, you can peer your Cloud Gateway network with your own network in AWS. This integration is facilitated by using AWS's [TransitGateway](https://aws.amazon.com/transit-gateway/) feature, enabling secure network connections across both platforms.
  - q: What types of data travel between the {{site.konnect_saas}} control plane and the data plane nodes, and how?
    a: |
      There are two types of data that travel between the planes: configuration
      and telemetry. Both use the secure TCP port `443`.

      * **Configuration:** The control plane sends configuration data to any connected
        data plane node in the cluster.

      * **Telemetry:** Data plane nodes send usage information to the control plane
        for Analytics and for account billing. Analytics tracks aggregate traffic by
        service, route, and the consuming application. For billing, Kong tracks the
        number of services, API calls, and active dev portals.

      Telemetry data does not include any customer information or any data processed
      by the data plane. All telemetry data is encrypted using mTLS.
  - q: How frequently does configuration data travel between the Konnect control plane and data plane nodes?
    a: When you make a configuration change on the control plane, that change is immediately pushed to any connected data plane nodes.
  - q: How frequently do data planes send telemetry data to the control plane?
    a: |
      Data planes send messages every 1 second by default. You can configure this interval using the [`analytics_flush_interval`](/gateway/latest/reference/configuration/#analytics_flush_interval) setting.
  - q: What happens if {{site.konnect_saas}} goes down?
    a: |
      If the Kong-hosted control plane goes down, the control plane/data plane
      connection gets interrupted. You can't access the control plane or
      change any configuration during this time.

      A connection interruption has no negative effect on the function of your
      data plane nodes. They continue to proxy and route traffic normally. 
      For more information, see [Control Plane outage management](/gateway/cp-outage/).
  - q: What happens if the control plane and data plane nodes disconnect?
    a: |
      If a data plane node becomes disconnected from its control plane, configuration can't
      travel between them. In that situation, the data plane node continues to use cached
      configuration until it reconnects to the control plane and receives new
      configuration.

      Whenever a connection is re-established with the control plane, it pushes the latest 
      configuration to the data plane node. It doesn't queue up or try to apply older changes.

      If your control plane is a {{site.mesh_product_name}} global control plane, see [Failure modes](/mesh/latest/production/deployment/multi-zone/#failure-modes) in the {{site.mesh_product_name}} documentation for more details on what happens when there are {{site.mesh_product_name}} connectivity issues.
  - q: If the data plane loses communication with the control plane, what happens to telemetry data?
    a: |
      If a data plane loses contact with the control plane, the data plane accumulates request data into a buffer.
      Once the buffer fills up, the data plane starts dropping older data. 
      The faster your requests come in, the faster the buffer fills up.

      By default, the buffer limit is 100000 requests. You can configure a custom buffer amount using the 
      [`analytics_buffer_size_limit`](/gateway/latest/reference/configuration/#analytics_buffer_size_limit) setting.
  - q: How long can data plane nodes remain disconnected from the control plane?
    a: |
      A data plane node will keep pinging the
      control plane, until the connection is re-established or the data plane node
      is stopped.

      The data plane node needs to connect to the control plane at least once.
      The control plane pushes configuration to the data plane, and each data plane
      node caches that configuration in-memory. It continues to use this cached
      configuration until it receives new instructions from the control plane.

      There are situations that can cause further problems:
      * If the license that the data plane node received from the control plane expires,
      the node stops working.
      * If the data plane node's configuration cache file (`config.json.gz`) or directory (`dbless.lmdb`)
      gets deleted, it loses access to the last known configuration and starts
      up empty.
  - q: Can I restart a data plane node if the control plane is down or disconnected?
    a: Yes. If you restart a data plane node, it uses a cached configuration to continue functioning the same as before the restart.
  - q: Can I create a new data plane node when the connection is down?
    a: Yes. {{site.base_gateway}} can support configuring new data plane nodes in the event of a control plane outage. For more information, see [Control Plane outage management](/gateway/cp-outage/). 
  - q: Can I create a backup configuration to use in case the cache fails?
    a: You can set the [`declarative_config`](/gateway/latest/reference/configuration/#declarative_config)option to load a fallback YAML config.
  - q: Can I change a data plane node's configuration when it's disconnected from the control plane?
    a: |
      Yes, if necessary, though any manual configuration will be overwritten the next
      time the control plane connects to the node.

      You can load configuration manually in one of the following ways:
      * Copy the configuration cache file (`config.json.gz`) or directory (`dbless.lmdb`) from another data
      plane node with a working connection and overwrite the cache file on disk
      for the disconnected node.
      * Remove the cache file, then start the data plane node with
      [`declarative_config`](/gateway/latest/reference/configuration/#declarative_config)
      to load a fallback YAML config.
---


{{site.base_gateway}} deployments run either in either [managed](/dedicated-cloud-gateways/) or [hybrid mode](/gateway/hybrid-mode/), which means that there is
a separate control plane attached to a data plane consisting of one or more 
data plane nodes. Data traveling between control planes and data planes is secured through a
mutual TLS handshake.
Data plane nodes initiate the connection to the {{site.base_gateway}} control plane.
Once the connection is established, the control plane can send configuration data to the 
connected data plane nodes.

Normally, each data plane node maintains a persistent connection with the control
plane. The node sends a heartbeat to the control plane every 30 seconds to
keep the connection alive. If it receives no answer, it tries to reconnect to the
control plane after a 5-10 second delay. If communication is interrupted 
and either side can't send or receive config, data plane nodes can still continue 
proxying traffic to clients. 

Whenever a data plane node receives new configuration from the control plane,
it immediately loads that config into memory. At the same time, it caches
the config to the file system. By default, data plane nodes store their configuration in an
unencrypted LMDB database directory, `dbless.lmdb`, in {{site.base_gateway}}’s
prefix path.

## Secure Control Plane and Data Plane communications

{{site.konnect_short_name}} Control Planes support Data Planes authenticating either with a certificate key pair (a pinned certificate) or a certificate signed by a CA (a PKI certificate).
* **Pinned certificates**: The Data Planes authenticate to the Control Plane using a shared certificate. For this option, the Control Plane and Data Plane nodes are provisioned with the same certificate. The Control Plane validates that the Data Planes established connection using the pinned certificate. 
* **Public Key Infrastructure (PKI) certificates**: The Data Planes can establish connection using digital certificates signed by a certificate authority (CA). The Control Plane must be provisioned with the CA certificate. {{site.konnect_short_name}} uses this certificate to build a chain of trust by verifying the certificates presented by the Data Planes.  If there are intermediate authorities issuing the certificates, the Data Plane nodes must include the intermediate certificates while establishing connection to the Control Plane.

### Certificate chain 
You must upload enough of the certificate chain in the Control Plane so that the Control Plane can trust the certificate in the Data Plane request and authenticate.

Consider the following scenarios with this example cert chain:

| Certificate | Type         | Issuer                   |
|-------------|--------------|--------------------------|
| `cert1`     | Service      | Issued by Intermediary   |
| `cert2`     | Intermediary | Issued by Root           |
| `cert3`     | Root         | Issued by Root (Self-signed) |

* **Upload only `cert1` to the Control Plane**: This is the pinned certificate. You can include just `cert1` in your Data Plane request and not include the chain. The Control Plane doesn’t need to evaluate the issuer because it trusts the cert itself.
* **Upload only `cert2` to the Control Plane**: This would mean any cert coming in that has (issuer: intermediary) would be trusted. You can include just `cert1` in your Data Plane request. The Control Plane would trust any certificate issued by the intermediary public key. 
* **Upload only `cert3` to the Control Plane**: This is the typical PKI case. It means any cert signed by the root is trusted. However, since `cert1` is signed by an intermediary and `cert2` is signed by root, you need to include both `cert1` and `cert2` in your Data Plane request. The Control Plane would trust the whole chain because `cert2` is issued by `cert3` and `cert1` is issued by `cert2`.

### Generate certificates in {{site.konnect_short_name}} 
{{site.konnect_short_name}} provides several options to generate or add a certificate for your Data Plane nodes. 

#### Generate a certificate key pair

When you use the {{site.konnect_short_name}} wizard to create a Data Plane node, it generates a certificate key pair. Data planes can establish a connection with this certificate key pair (pinned cert).

1. Navigate to [**Gateway Manager**](https://cloud.konghq.com/gateway-manager/) in {{site.konnect_short_name}}.
1. Click on the Control Plane you want to create a Data Plane node for.
1. Click **Data Plane Nodes** in the sidebar.
1. Click **Create a New Data Plane Node**. 
1. Follow the instructions in the wizard to create a Data Plane node and generate the certificate key pair.

#### Generate a CA-signed certificate

Using the {{site.konnect_short_name}} UI, you can generate a CA certificate, which allows Data Planes to connect using a certificate signed by that CA (PKI). Alternatively you can upload your own CA using the upload option.

1. Navigate to [**Gateway Manager**](https://cloud.konghq.com/gateway-manager/) in {{site.konnect_short_name}}.
1. Click on the Control Plane you want to create a Data Plane node for.
1. From the Action menu, select **Data Plane Certificates**. 
1. Either upload or generate a certificate.

Certificates generated by {{site.konnect_short_name}} are valid for 10 years. If you bring your own certificates, make sure to review the expiration date and associated metadata. See [Renew Certificates for a Data Plane Node](/konnect/gateway-manager/data-plane-nodes/renew-certificates/) for more details.

## Use a forward proxy to secure communication across a firewall

If your Control Plane and Data Planes are separated by a firewall that routes external communications through a proxy, you can configure {{site.base_gateway}} to authenticate with the proxy server and allow traffic to pass through.

To use a forward proxy for Control Plane and Data Plane communication, you need to configure the following parameters in [`kong.conf`](/gateway/manage-kong-conf/):

{% navtabs "http-protocol-example" %}
{% navtab "HTTP example" %}
```
proxy_server = 'http://<username>:<password>@<proxy-host>:<proxy-port>'
proxy_server_ssl_verify = off
cluster_use_proxy = on
```
{% endnavtab %}
{% navtab "HTTPS example" %}
```
proxy_server = 'https://<username>:<password>@<proxy-host>:<proxy-port>'
proxy_server_ssl_verify = on
cluster_use_proxy = on
lua_ssl_trusted_certificate = system  # or <certificate> or <path-to-cert>
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

