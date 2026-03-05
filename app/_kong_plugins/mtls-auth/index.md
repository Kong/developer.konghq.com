---
title: 'Mutual TLS Authentication'
name: 'Mutual TLS Authentication'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Secure routes and services with client certificate and mutual TLS authentication'


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

icon: mtls-auth.png

categories:
  - authentication

search_aliases:
  - mtls
  - mtls authentication
  - mtls-auth
  - certificates

tags:
  - mtls
  - authentication

notes: | 
   <b>Serverless Gateways</b>: This plugin is not supported in serverless gateways because the 
   TLS handshake does not occur at the Kong layer in this setup. 

min_version:
  gateway: '1.0'

faqs:
  - q: Can the mTLS plugin read a certificate from a header?
    a: |
      No, the mTLS authentication plugin can't read certificates from headers.
      The mTLS plugin is only designed for traditional TLS termination. For reading client certificates from headers, use the [Header Cert Authentication plugin](/plugins/header-cert-auth/).
      
---

The MTLS Auth plugin lets you add mutual TLS authentication based on a client-supplied or a server-supplied certificate, 
and on the configured trusted certificate authority (CA) list.

If you need to read client certificates from headers, see the [Header Cert Authentication plugin](/plugins/header-cert-auth/).

{:.warning}
> **Important:** To use this plugin, you must add [certificate authority (CA) Certificates](/gateway/entities/ca-certificate/). Set them up before configuring the plugin.

## How does the mTLS plugin work?

The mTLS plugin automatically maps certificates to Consumers based on the common name field.
To authenticate a Consumer with mTLS, it must provide a valid certificate and
complete a mutual TLS handshake with {{site.base_gateway}}.

The plugin validates the certificate provided against the configured CA list based on the
requested Route or Service:
* If the certificate is not trusted, or expired, the response is `HTTP 401 TLS certificate failed verification`.
* If no valid certificate is provided (including HTTP requests), the response is `HTTP 401 No required TLS certificate was sent`.  
  However, if `config.anonymous` is set, the request is allowed using the anonymous Consumer.

### Client certificate request

Client certificates are requested during the [`ssl_certificate_by_lua` phase](/gateway/entities/plugin/#plugin-contexts), where {{site.base_gateway}} doesn't have access to Route or Workspace information. 
Because of this, {{site.base_gateway}} requests a client certificate during every TLS handshake if the `mtls-auth` plugin is configured on any Route or Service.

In most cases, if a client doesn't present a certificate, it won't affect proxying—unless the specific Route or Service requires `mtls-auth`.
The main exception is desktop browsers, which may prompt users to select a certificate, potentially causing a confusing user experience even when the certificate isn't needed.

To optimize TLS handshakes, {{site.base_gateway}} builds an in-memory map of SNIs from Routes that require client certificates. 
This helps limit unnecessary certificate requests while ensuring mTLS is enforced when needed. 
The map relies on Routes having the `SNIs` attribute set. 
If any Route lacks an SNI, {{site.base_gateway}} must request a client certificate during every TLS handshake.

Certificate request behavior based on plugin scope:

* **Plugin applied globally**: mTLS is enforced on every request across all Workspaces.
* **Plugin applied at the Service level**: If any associated Route lacks an SNI, mTLS is enforced on every request.
* **Plugin applied at the Route level**:
  * If any Route lacks an SNI, mTLS is enforced on every request.
  * If all Routes have SNIs, mTLS is enforced only for matching SNI requests.

SNIs must be set for all Routes that mutual TLS authentication uses.

{:.warning}
> When using the plugin with [expressions routes](/gateway/routing/expressions/), 
the client certificate will always be requested, even if the routes are configured with SNIs. 

### Sending the CA DNs during TLS handshake

By default, {{site.base_gateway}} does not send the CA Distinguished Name (CA DN) list during the TLS handshake. Specifically, the `certificate_authorities` field in the `CertificateRequest` message is empty.

Some clients use the CA DN list to help select the correct certificate. To support this, set `config.send_ca_dn` to `true`. 
This adds the CA certificates defined in `config.ca_certificate` to the appropriate SNI entries.

As noted in [Client certificate request](#client-certificate-request), {{site.base_gateway}} does not have access to Route information during the `ssl_certificate_by_lua` phase. 
Instead, it builds an in-memory map of SNIs. 
The CA DN list is linked to these SNIs, and if multiple `mtls-auth` plugins with different `config.ca_certificate` values are applied to the same SNI, their CA DNs are merged.

CA DN list association depends on plugin scope:

* Global scope: CA DNs are linked to a special SNI `*`.
* Service level:
  * CA DNs are associated with each SNI of the Service's Routes.
  * If a Route has no SNI, CA DNs are linked to `*`.
* Route level:
  * CA DNs are associated with each SNI on the Route.
  * If no SNI is configured, CA DNs are linked to `*`.

During the mTLS handshake:

* If the client includes a known SNI in the `ClientHello`, the corresponding CA DN list is sent in the `CertificateRequest`.
* If the client does not send an SNI or sends an unknown one, {{site.base_gateway}} only sends the CA DN list associated with `*`—and only if a client certificate is being requested.

## Manual mappings between Certificate and Consumer objects

{% include_cached plugins/manual-consumer-mapping.md name=page.name slug=page.slug %}

## Troubleshooting authentication failure

When authentication fails, the client doesn't have access to any details that explain the failure. 
The security reason for this omission is to prevent malicious reconnaissance. 

Instead, the details are recorded inside [{{site.base_gateway}}'s error logs](/gateway/logs/) under the `[mtls-auth]` filter.
