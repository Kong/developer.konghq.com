---
title: 'ACME'
name: 'ACME'

content_type: plugin

publisher: kong-inc
description: Let's Encrypt and ACMEv2 integration with {{site.base_gateway}}

related_resources:
  - text: Test certificate generation locally with ngrok and the ACME plugin
    url: /how-to/test-certificate-generation-locally-with-ngrok-and-acme/
  - text: Key entity
    url: /gateway/entities/key/
  - text: Key Set entity
    url: /gateway/entities/key-set/


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways

icon: acme.png

categories:
  - security

tags:
  - security
  - certificates

search_aliases:
  - let's encrypt
  - certificates

notes: | 
   **Serverless Gateways**: This plugin is not supported in serverless gateways because the 
   TLS handshake does not occur at the Kong layer in this setup. 

min_version:
  gateway: '2.0'
---

The ACME plugin allows {{site.base_gateway}} to apply SSL certificates from Let's Encrypt or any other ACMEv2 service and serve them dynamically for TLS requests.
You can also configure a threshold time for automatic renewal. 

## How it works

The ACME plugin uses the [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/), which lets you verify domain ownership before issuing an SSL certificate. 
The plugin generates a challenge token and key thumbprint, then presents them to Let's Encrypt or another ACMEv2 service when requested.

To use this plugin, you need:
* A public IP and a resolvable DNS
* This challenge can only be done on port 80, so {{site.base_gateway}} needs to accept proxy traffic this port. You can configure this with `proxy_listen` in `kong.conf`.

Wildcard (`*`) certificates are not supported. Each domain must have its own certificate.

**This plugin can only be configured as a global plugin.** 
The plugin terminates the `/.well-known/acme-challenge/` path for matching domains. 
To create certificates and terminate challenges only for certain domains, refer to the [configuration reference](/plugins/acme/reference/).


### Running with or without a database

In a database-backed deployment, the plugin creates an SNI and certificate entity in {{site.base_gateway}} to
serve the certificate. If the SNI or certificate for the current request is already set
in the database, it will be overwritten.

In DB-less mode, the plugin takes over certificate handling. The plugin overrides the SNI or
certificate entity if they are already defined in {{site.base_gateway}}.

### Supported storage types

The ACME plugin needs a backend storage to store certificates, challenge tokens, and key thumbprints.

You can set the backend storage for the plugin using the [`config.storage`](/plugins/acme/reference/#schema--config-storage) parameter.
The backend storage available depends on the [topology](/gateway/deployment-topologies/) of your {{site.base_gateway}} environment: 

<!--vale off-->

{% feature_table %}
item_title: Storage type
columns:
  - title: Description
    key: description
  - title: Traditional mode
    key: traditional
  - title: Hybrid mode
    key: hybrid
  - title: DB-less
    key: dbless
  - title: "{{site.konnect_short_name}}"
    key: konnect
features:
  - title: "`shm`"
    description: "Lua shared dict storage. This storage is volatile between Nginx restarts (not reloads)."
    traditional: true
    hybrid: false
    dbless: true
    konnect: false
  - title: "`kong` <sup>1</sup>"
    description: "{{site.base_gateway}} database storage."
    traditional: true
    hybrid: true
    dbless: false
    konnect: false
  - title: "`redis`"
    description: "[Redis-based](https://redis.io/docs/latest/) storage."
    traditional: true
    hybrid: true
    dbless: true
    konnect: true
  - title: "`consul`"
    description: "[HashiCorp Consul](https://www.consul.io/) storage."
    traditional: true
    hybrid: true
    dbless: true
    konnect: true
  - title: "`vault`"
    description: "[HashiCorp Vault](https://www.vaultproject.io/) storage. Only the [KV V2](https://developer.hashicorp.com/vault/api-docs/secret/kv/kv-v2) backend is supported."
    traditional: true
    hybrid: true
    dbless: true
    konnect: true
{% endfeature_table %}

<!--vale on-->

{:.info}
> **\[1\]**: Due to the current limitations of hybrid mode, `kong` storage only supports certificate generation from
the Admin API but not the proxy side, as the Data Planes don't have access to the {{site.base_gateway}} database. 
See the [hybrid mode workflow](#hybrid-mode-workflow) for details. 

To configure a storage type other than `kong` (default), see the [ACME plugin example configurations](/plugins/acme/examples/).

### Workflow

An HTTP-01 challenge workflow between the {{site.base_gateway}} and the ACME server looks like this:

1. The client sends a proxy or Admin API request that triggers certificate generation for `example-domain.com`.
2. {{site.base_gateway}} sends a request to the ACME server to start the validation process.
3. If `example-domain.com` is publicly resolvable to the {{site.base_gateway}} instance that serves the challenge response, 
then the ACME server returns challenge instructions to {{site.base_gateway}}.
4. {{site.base_gateway}} executes the challenge against the `example-domain.com`, validates the results against the ACME server,
5. If the challenge passes, {{site.base_gateway}} downloads the SSL certificate from the ACME server and uses it to serve TLS requests.

See the following diagram, which breaks down the process in more detail:

<!--vale off-->

{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client
    participant kong as {{site.base_gateway}}
    participant acme as ACME Server
    participant domain as example-domain.com
    participant storage as Storage <br>(internal or external)

    client->>kong: Proxy or Admin API request <br> for example-domain.com
    kong->>acme: Start validation for example-domain.com
    note left of acme: example-domain.com is <br> publicly resolvable to {{site.base_gateway}}
    acme->>kong: Return challenge instructions
    kong->>domain: Use challenge against example-domain.com
    domain->>kong: Execute challenge and send response
    kong->>acme: Check challenge status
    acme->>kong: Download SSL certificate
    kong->>storage: Place certificate in storage
    storage->>kong: Use new SSL certificate for TLS requests
{% endmermaid %}

<!--vale on-->

In hybrid mode, the process is essentially the same, but both the Control Plane and Data Planes need access to the same storage. 
If the storage is external, they both need to connect to the same external storage cluster.
We also recommend setting up replicas to avoid having the Data Planes and Control Planes connect to same node directly for external storage.

## Renewing certificates

The plugin runs daily checks and automatically renews all certificates that
will expire in less than the configured [`config.renew_threshold_days`](/plugins/acme/reference/#schema--config-renew-threshold-days) value. If the renewal
of an individual certificate throws an error, the plugin will continue renewing the
other certificates. It will try renewing all certificates, including those that previously
failed, once per day. 

Renewal configuration is stored in the configured storage backend.
If the storage is cleared or modified outside of {{site.base_gateway}}, renewal might not complete properly.

You can also actively trigger the renewal by sending the following request that schedules a renewal in the background:

```bash
curl http://localhost:8001/acme -XPATCH
```

## Switching storage types

{{site.base_gateway}} tracks SSL certificates in the defined storage type only.
For example, if the storage type is set to `kong`, the certificates and their renewal configuration will be stored in the {{site.base_gateway}} database.

If you change the storage type, the previous configuration will be lost. 
For example, if you have the storage type set to  `kong` and change it to `redis`, all certificates that were tracked for renewal when using the Kong DB for storage will no longer be tracked and renewed automatically. 

When switching between storage types, we recommend deleting existing certificates.

You can see what certificates {{site.base_gateway}} is currently is aware of using the [`/acme/certificates`](/plugins/acme/api/#/operations/listCertificates) endpoint of the Admin API.

## EAB support

The ACME plugin supports external account binding (EAB) with the [`config.eab_kid`](/plugins/acme/reference/#schema--config-eab-kid) and [`config.eab_hmac_key`](/plugins/acme/reference/#schema--config-eab-hmac-key) values.

If you're using [ZeroSSL](https://zerossl.com/), the provider's external account can be registered automatically, without specifying the KID or HMAC key.


{% include plugins/redis-cloud-auth.md %}
