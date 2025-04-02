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
  - q: How does network peering work with Dedicated Cloud Gateway nodes?
    a: Each Cloud Gateway node is part of a dedicated Cloud Gateway network that corresponds to a specific cloud region, such as `us-east-1` or `us-west-2`. For enhanced security and seamless connectivity between your cloud network and the {{site.konnect_short_name}} environment, you can peer your Cloud Gateway network with your own network in AWS. This integration is facilitated by using AWS's [Transit Gateway](/dedicated-cloud-gateways/transit-gateways/) feature, enabling secure network connections across both platforms.
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

      If your Control Plane is a {{site.mesh_product_name}} global Control Plane, see [Failure modes](/mesh/latest/production/deployment/multi-zone/#failure-modes) in the {{site.mesh_product_name}} documentation for more details on what happens when there are {{site.mesh_product_name}} connectivity issues.
  - q: If the Data Plane loses communication with the Control Plane, what happens to telemetry data?
    a: |
      If a Data Plane loses contact with the Control Plane, the Data Plane accumulates request data into a buffer.
      Once the buffer fills up, the Data Plane starts dropping older data. 
      The faster your requests come in, the faster the buffer fills up.

      By default, the buffer limit is 100000 requests. You can configure a custom buffer amount using the 
      [`analytics_buffer_size_limit`](/gateway/configuration/#analytics_buffer_size_limit) setting.
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
    a: You can set the [`declarative_config`](/gateway/configuration/#declarative_config) option to load a fallback YAML config.
  - q: Can I change a Data Plane node's configuration when it's disconnected from the Control Plane?
    a: |
      Yes, if necessary, though any manual configuration will be overwritten the next
      time the Control Plane connects to the node.

      You can load configuration manually in one of the following ways:
      * Copy the configuration cache file (`config.json.gz`) or directory (`dbless.lmdb`) from another data
      plane node with a working connection and overwrite the cache file on disk
      for the disconnected node.
      * Remove the cache file, then start the Data Plane node with
      [`declarative_config`](/gateway/configuration/#declarative_config)
      to load a fallback YAML config.
  - q: "I receive the following error when starting {{site.base_gateway}}: `2022/04/11 12:01:07 [crit] 32790#0: *7 [lua] init.lua:648: init_worker(): worker initialization error: failed to create and open LMDB database: MDB_CORRUPTED: Located page was wrong type; this node must be restarted, context: init_worker_by_lua*`"
    a: Your local configuration cache is corrupt. Remove your LMDB cache (located at `<prefix>/dbless.lmdb`, which is located at  [`/usr/local/kong/dbless.lmdb` by default](/gateway/configuration/#prefix)) and restart {{site.base_gateway}}. This forces the {{site.base_gateway}} node to reload the configuration from the Control Plane because the corrupted cache was deleted.
---


When {{site.base_gateway}} deployments run either in either [managed](/dedicated-cloud-gateways/) or [hybrid mode](/gateway/hybrid-mode/), this means that there is
a separate Control Plane attached to a Data Plane consisting of one or more 
Data Plane nodes. Data traveling between Control Planes and Data Planes is secured through a
mutual TLS handshake.
Data plane nodes initiate the connection to the {{site.base_gateway}} Control Plane.
Once the connection is established, the Control Plane can send configuration data to the 
connected Data Plane nodes.

Normally, each Data Plane node maintains a persistent connection with the control
plane. The node sends a heartbeat to the Control Plane every 30 seconds to
keep the connection alive. If it receives no answer, it tries to reconnect to the
Control Plane after a 5-10 second delay. If communication is interrupted 
and either side can't send or receive config, Data Plane nodes can still continue 
proxying traffic to clients. 

Whenever a Data Plane node receives new configuration from the Control Plane,
it immediately loads that config into memory. At the same time, it caches
the config to the file system. By default, Data Plane nodes store their configuration in an
unencrypted LMDB database directory, `dbless.lmdb`, in {{site.base_gateway}}’s
[`prefix` path](/gateway/configuration/#prefix).

### DP node start sequence

When set as a DP node, {{site.base_gateway}} processes configuration in the
following order:

1. **Config cache**: If the local config cache `dbless.lmdb` exists in the [`kong_prefix` path]((/gateway/configuration/#prefix)) (`/usr/local/kong` by default), the DP node loads it as configuration.
2. **`declarative_config` exists**: If there is no config cache and the
`declarative_config` parameter is set, the DP node loads the specified file.
3. **Empty config**: If there is no config cache or declarative
configuration file available, the node starts with empty configuration. In this
state, it returns 404 to all requests.
4. **Contact CP Node**: In all cases, the DP node contacts the CP node to retrieve
the latest configuration. If successful, it gets stored in the local config
cache (`dbless.lmdb`).

## Secure Control Plane and Data Plane communications

{{site.base_gateway}} Control Planes support Data Planes authenticating either with a certificate key pair (a pinned certificate) or a certificate signed by a CA (a PKI certificate).
* **Pinned certificates**: The Data Planes authenticate to the Control Plane using a shared certificate. For this option, the Control Plane and Data Plane nodes are provisioned with the same certificate. The Control Plane validates that the Data Planes established connection using the pinned certificate. 
* **Public Key Infrastructure (PKI) certificates**: The Data Planes can establish connection using digital certificates signed by a certificate authority (CA). The Control Plane must be provisioned with the CA certificate. {{site.base_gateway}} uses this certificate to build a chain of trust by verifying the certificates presented by the Data Planes.  If there are intermediate authorities issuing the certificates, the Data Plane nodes must include the intermediate certificates while establishing connection to the Control Plane.

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

## Generate certificates in {{site.konnect_short_name}} 
{{site.konnect_short_name}} provides several options to generate or add a certificate for your Data Plane nodes. 

### Generate a certificate key pair

When you use the {{site.konnect_short_name}} wizard to create a Data Plane node, it generates a certificate key pair. Data planes can establish a connection with this certificate key pair (pinned cert).

1. Navigate to [**Gateway Manager**](https://cloud.konghq.com/gateway-manager/) in {{site.konnect_short_name}}.
1. Click on the Control Plane you want to create a Data Plane node for.
1. Click **Data Plane Nodes** in the sidebar.
1. Click **Create a New Data Plane Node**. 
1. Follow the instructions in the wizard to create a Data Plane node and generate the certificate key pair.

### Generate a CA-signed certificate

Using the {{site.konnect_short_name}} UI, you can generate a CA certificate, which allows Data Planes to connect using a certificate signed by that CA (PKI). Alternatively you can upload your own CA using the upload option.

1. Navigate to [**Gateway Manager**](https://cloud.konghq.com/gateway-manager/) in {{site.konnect_short_name}}.
1. Click on the Control Plane you want to create a Data Plane node for.
1. From the Action menu, select **Data Plane Certificates**. 
1. Either upload or generate a certificate.

Certificates generated by {{site.konnect_short_name}} are valid for 10 years. If you bring your own certificates, make sure to review the expiration date and associated metadata. See [Renew Certificates for a Data Plane Node](/konnect/gateway-manager/data-plane-nodes/renew-certificates/) for more details.

## Generate a certificate/key pair in {{site.base_gateway}} on-prem

In hybrid mode, a mutual TLS handshake (mTLS) is used for authentication so the
actual private key is never transferred on the network, and communication
between CP and DP nodes is secure.

Before using hybrid mode, you need a certificate/key pair.
{{site.base_gateway}} provides two modes for handling certificate/key pairs:

* **Shared mode:** (Default) Use the {{site.base_gateway}} CLI to generate a certificate/key
pair, then distribute copies across nodes. The certificate/key pair is shared
by both CP and DP nodes.
* **PKI mode:** Provide certificates signed by a central certificate authority
(CA). {{site.base_gateway}} validates both sides by checking if they are from the same CA. This
eliminates the risks associated with transporting private keys.

{:.warning}
> **Warning:** If you have a TLS-aware proxy between the DP and CP nodes, you
must use PKI mode and set `cluster_server_name` to the CP hostname in
`kong.conf`. Do not use shared mode, as it uses a non-standard value for TLS server name
indication, and this will confuse TLS-aware proxies that rely on SNI to route
traffic.

For a breakdown of the properties used by these modes, see the
[configuration reference](#configuration-reference).

### Shared mode

{:.warning}
> **Warning:** Protect the Private Key. Ensure the private key file can only be accessed by {{site.base_gateway}} nodes that belong to the cluster. If the key is compromised, you must regenerate and replace certificates and keys on all CP and DP nodes.

1. On an existing {{site.base_gateway}} instance, create a certificate/key pair:
    ```bash
    kong hybrid gen_cert
    ```
    This will generate `cluster.crt` and `cluster.key` files and save them to
    the current directory. By default, the certificate/key pair is valid for three
    years, but can be adjusted with the `--days` option. See `kong hybrid --help`
    for more usage information.

2. Copy the `cluster.crt` and `cluster.key` files to the same directory
on all {{site.base_gateway}} CP and DP nodes; e.g., `/cluster/cluster`.
  Set appropriate permissions on the key file so it can only be read by {{site.base_gateway}}.

### PKI mode

With PKI mode, the Hybrid cluster can use certificates signed by a central
certificate authority (CA).

In this mode, the Control Plane and Data Plane don't need to use the same
`cluster_cert` and `cluster_cert_key`. Instead, {{site.base_gateway}} validates both sides by
checking if they are from the same CA. Certificates on CP and DP must contain the `TLS Web Server Authentication` and `TLS Web Client Authentication` as X509v3 Extended Key Usage extension, respectively.

{{site.base_gateway}} doesn't validate the CommonName (CN) in the DP certificate, it can take an arbitrary value.

Prepare your CA certificates on the hosts where {{site.base_gateway}} will be running.

{% navtabs "PKI cert" %}
{% navtab "CA Certificate Example" %}
Typically, a CA certificate will look like this:

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            5d:29:73:bf:c3:da:5f:60:69:da:73:ed:0e:2e:97:6f:7f:4c:db:4b
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: O = Kong Inc., CN = Hybrid Root CA
        Validity
            Not Before: Jul  7 12:36:10 2020 GMT
            Not After : Jul  7 12:36:40 2023 GMT
        Subject: O = Kong Inc., CN = Hybrid Root CA
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:df:49:9f:39:e6:2c:52:9f:46:7a:df:ae:7b:9b:
                    87:1e:76:bb:2e:1d:9c:61:77:07:e5:8a:ba:34:53:
                    3a:27:4c:1e:76:23:b4:a2:08:80:b4:1f:18:7a:0b:
                    79:de:ea:8c:23:94:e6:2f:57:cf:27:b4:0a:52:59:
                    90:2c:2b:86:03
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                8A:0F:07:61:1A:0F:F4:B4:5D:B7:F3:B7:28:D1:C5:4B:81:A2:B9:25
            X509v3 Authority Key Identifier:
                keyid:8A:0F:07:61:1A:0F:F4:B4:5D:B7:F3:B7:28:D1:C5:4B:81:A2:B9:25

    Signature Algorithm: ecdsa-with-SHA256
         30:45:02:20:68:3c:d1:f3:63:a2:aa:b4:59:c9:52:af:33:b7:
         3f:ca:3a:2b:1c:9d:87:0c:c0:47:ff:a2:c4:af:3e:b0:36:29:
         02:21:00:86:ce:d0:fc:ba:92:e9:59:16:1c:c3:b2:11:11:ed:
         01:5d:16:49:d0:f9:0c:1d:35:0d:40:ba:19:98:31:76:57
```
{% endnavtab %}

{% navtab "Certificate on CP" %}
Here is an example of a certificate on a Control Plane:

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            18:cc:a3:6b:aa:77:0a:69:c6:d5:ff:12:be:be:c0:ac:5c:ff:f1:1e
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN = Hybrid Intermediate CA
        Validity
            Not Before: Jul 31 00:59:29 2020 GMT
            Not After : Oct 29 00:59:59 2020 GMT
        Subject: CN = control-plane.kong.yourcorp.tld
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:f8:3a:a9:d2:e2:79:19:19:f3:1c:58:a0:23:60:
                    78:04:1f:7e:e2:bb:60:d2:29:50:ad:7c:9b:8e:22:
                    1c:54:c2:ce:68:b8:6c:8a:f6:92:9d:0c:ce:08:d3:
                    aa:0c:20:67:41:32:18:63:c9:dd:50:31:60:d6:8b:
                    8d:f9:7b:b5:37
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Key Agreement
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Key Identifier:
                70:C7:F0:3B:CD:EB:8D:1B:FF:6A:7C:E0:A4:F0:C6:4C:4A:19:B8:7F
            X509v3 Authority Key Identifier:
                keyid:16:0D:CF:92:3B:31:B0:61:E5:AB:EE:91:42:B9:60:56:0A:88:92:82

            X509v3 Subject Alternative Name:
                DNS:control-plane.kong.yourcorp.tld, DNS:alternate-control-plane.kong.yourcorp.tld
            X509v3 CRL Distribution Points:

                Full Name:
                  URI:https://crl-service.yourcorp.tld/v1/pki/crl

    Signature Algorithm: ecdsa-with-SHA256
         30:44:02:20:5d:dd:ec:a8:4f:e7:5b:7d:2f:3f:ec:b5:40:d7:
         de:5e:96:e1:db:b7:73:d6:84:2e:be:89:93:77:f1:05:07:f3:
         02:20:16:56:d9:90:06:cf:98:07:87:33:dc:ef:f4:cc:6b:d1:
         19:8f:64:ee:82:a6:e8:e6:de:57:a7:24:82:72:82:49
```
{% endnavtab %}

{% navtab "Certificate on DP" %}
Here is an example of a certificate on a Data Plane:

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            4d:8b:eb:89:a2:ed:b5:29:80:94:31:e4:94:86:ce:4f:98:5a:ad:a0
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN = Hybrid Intermediate CA
        Validity
            Not Before: Jul 31 00:57:01 2020 GMT
            Not After : Oct 29 00:57:31 2020 GMT
        Subject: CN = kong-dp-ce39edecp.service
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:19:51:80:4c:6d:8c:a8:05:63:42:71:a2:9a:23:
                    34:34:92:c6:2a:d3:e5:15:6e:36:44:85:64:0a:4c:
                    12:16:82:3f:b7:4c:e1:a1:5a:49:5d:4c:5e:af:3c:
                    c1:37:e7:91:e2:b5:52:41:a0:51:ac:13:7b:cc:69:
                    93:82:9b:2f:e2
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Key Agreement
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Subject Key Identifier:
                25:82:8C:93:85:35:C3:D6:34:CF:CB:7B:D6:14:97:46:84:B9:2B:87
            X509v3 Authority Key Identifier:
                keyid:16:0D:CF:92:3B:31:B0:61:E5:AB:EE:91:42:B9:60:56:0A:88:92:82
            X509v3 CRL Distribution Points:

                Full Name:
                  URI:https://crl-service.yourcorp.tld/v1/pki/crl

    Signature Algorithm: ecdsa-with-SHA256
         30:44:02:20:65:2f:5e:30:f7:a4:28:14:88:53:58:c5:85:24:
         35:50:25:c9:fe:db:2f:72:9f:ad:7d:a0:67:67:36:32:2b:d2:
         02:20:2a:27:7d:eb:75:a6:ee:65:8b:f1:66:a4:99:32:56:7c:
         ad:ca:3a:d5:50:8f:cf:aa:6d:c2:1c:af:a4:ca:75:e8
```
{% endnavtab %}
{% endnavtabs %}

#### (Optional) Revocation checks of Data Plane certificates

When {{site.base_gateway}} is running hybrid mode with PKI mode, the Control Plane can be configured to
optionally check for revocation status of the connecting Data Plane certificate.

The supported method is through Online Certificate Status Protocol (OCSP) responders.
Issued Data Plane certificates must contain the Certificate Authority Information Access extension
that references the URI of OCSP responder that can be reached from the Control Plane. `cluster_oscp` affects all hybrid mode connections established from a Data Plane to its Control Plane.

To enable OCSP checks, set the `cluster_ocsp` config on the Control Plane to one of the following values:

<!--vale off-->
{% kong_config_table %}
config:
  - name: cluster_ocsp
{% endkong_config_table %}
<!--vale on-->


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

