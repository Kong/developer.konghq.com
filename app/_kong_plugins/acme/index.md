---
title: 'ACME'
name: 'ACME'

content_type: plugin

publisher: kong-inc
description: Let's Encrypt and ACMEv2 integration with {{site.base_gateway}}
tier: enterprise


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
  - certificates

search_aliases:
  - let's encrypt
  - certificates
---

The ACME plugin allows {{site.base_gateway}} to apply certificates from Let’s Encrypt or any other ACMEv2 service and serve them dynamically. You can also configure a threshold time for renewal. 

## How it works

The ACME plugin uses the [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/), which lets you verify domain ownership before issuing an SSL certificate.

To use this plugin, you need:
* A public IP and a resolvable DNS
* This challenge can only be done on port 80, so {{site.base_gateway}} needs to accept proxy traffic this port

Wildcard or star (`*`) certificates are not supported. Each domain must have its
own certificate.

{:.info}
> **Serverless Gateways**: This plugin is not supported in serverless gateways because the
 TLS handshake doesn't occur at the {{site.base_gateway}} layer in this setup. 

### Running with or without a database

In a database-backed deployment, the plugin creates an SNI and certificate entity in {{site.base_gateway}} to
serve the certificate. If the SNI or certificate for the current request is already set
in the database, it will be overwritten.

In DB-less mode, the plugin takes over certificate handling. If the SNI or
certificate entity is already defined in {{site.base_gateway}}, it will be overridden by the
response.

### Supported storage types

The ACME plugin needs a backend storage to store challenge tokens and keys.

You can set the backend storage for the plugin using the [`config.storage`](/plugins/acme/reference/#config-storage) parameter.
The backend storage available depends on the [topology](/gateway/deployment-models/) of your {{site.base_gateway}} environment: 

Storage type | Description   | Traditional mode | Hybrid mode | DB-less | {{site.konnect_short_name}}
-------------|---------------|------------------|-------------|---------|----------------------------
`shm` | Lua shared dict storage. <br> This storage is volatile between Nginx restarts (not reloads). | ✅ | ❌ | ✅ | ❌
`kong`| {{site.base_gateway}} database storage. | ✅ | ✅ <sup>1</sup> | ❌ | ❌
`redis` | [Redis-based](https://redis.io/docs/latest/) storage.  | ✅ | ✅ | ✅ | ✅
`consul` | [HashiCorp Consul](https://www.consul.io/) storage. | ✅ | ✅ | ✅ | ✅
`vault` | [HashiCorp Vault](https://www.vaultproject.io/) storage. <br> _Only the [KV V2](https://www.vaultproject.io/api/secret/kv/kv-v2.html) backend is supported._ | ✅ | ✅ | ✅ | ✅

{:.info}
> **\[1\]**: Due to current the limitations of hybrid mode, `kong` storage only supports certificate generation from
the Admin API but not the proxy side, as the data planes don't have access to the {{site.base_gateway}} database. 
See the [hybrid mode workflow](#hybrid-mode-workflow) for details. 

To configure a storage type other than `kong` (default), see the [ACME plugin example configurations](/plugins/acme/examples/).


### Traditional and DB-less mode workflow

An HTTP-01 challenge workflow between the {{site.base_gateway}} and the ACME server looks like this:

1. The client sends a proxy or Admin API request that triggers certificate generation for `example-domain.com`.
2. {{site.base_gateway}} sends a request to the ACME server to start the validation process.
3. If `example-domain.com` is publicly resolvable to the {{site.base_gateway}} instance that serves the challenge response, then the ACME server returns the challenge response detail to {{site.base_gateway}}.
4. The ACME server checks if the previous challenge has a response at `example-domain.com`.
5. {{site.base_gateway}} checks the challenge status and, if passed, downloads the certificate from the ACME server.
6. {{site.base_gateway}} uses the new certificate to serve TLS requests.

### Hybrid mode workflow

#### Kong database storage

This storage option is available in on-prem hybrid mode, but it isn't available in {{site.konnect_short_name}}.
Setting the storage strategy to `kong` tells the plugin to store challenge tokens and keys in the {{site.base_gateway}} datastore.

`kong` storage in hybrid mode works in following way:

1. The client sends a proxy or Admin API request that triggers certificate generation for `example-domain.com`.
2. The Kong control plane requests the ACME server to start the validation process.
3. If `example-domain.com` is publicly resolvable to the data plane that serves the challenge response, 
then the ACME server returns a challenge response detail to the control plane.
4. The control plane propagates the challenge response detail to the data plane.
6. The ACME server checks if the previous challenge has a response at `example-domain.com`.
7. The control plane checks the challenge status and, if passed, downloads the certificate from the ACME server.
8. The control plane propagates the new certificates to the data plane.
9. (For proxy requests) The data plane uses the new certificate to serve TLS requests.

All external storage types work as usual in hybrid mode. 
Both the control plane and data planes need to connect to the same external storage cluster. 
We also recommend setting up replicas to avoid connecting to same node directly for external storage.

#### External storage 

External storage in hybrid mode (`redis`, `consul`, or `vault`) works in the following way:

1. The client sends a proxy or Admin API request that triggers certificate generation for `example-domain.com`.
2. The Kong control plane or data plane requests the ACME server to start the validation process.
3. The ACME server returns the challenge response detail to the control or data plane.
4. If `example-domain.com` is publicly resolvable to the data plane that reads and serves the challenge response from external storage, the control plane or data plane stores the challenge response detail in external storage.
5. The ACME server checks if the previous challenge has a response at `example-domain.com`.
6. The control plane or data plane checks the challenge status and, if passed, downloads the certificate from the ACME server.
7. The control plane or data plane stores the new certificates in external storage.
8. (For proxy requests) The data plane reads from external storage and uses the new certificate to serve TLS requests.

## Renewing certificates

The plugin runs daily checks and automatically renews all certificates that
will expire in less than the configured `renew_threshold_days` value. If the renewal
of an individual certificate throws an error, the plugin will continue renewing the
other certificates. It will try renewing all certificates, including those that previously
failed, once per day. 

Renewal configuration is stored in the configured storage backend.
If the storage is cleared or modified outside of {{site.base_gateway}}, renewal might not complete properly.

You can also actively trigger the renewal. The following request
schedules a renewal in the background and returns immediately:

```bash
curl http://localhost:8001/acme -XPATCH
```

## EAB support

The ACME plugin supports external account binding (EAB) with the `config.eab_kid` and `config.eab_hmac_key` values.

If using [ZeroSSL](https://zerossl.com/), the provider's external account can be registered automatically, without specifying the `eab_kid` or `eab_hmac_key`.