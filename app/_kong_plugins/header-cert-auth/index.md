---
title: 'Header Cert Authentication'
name: 'Header Cert Authentication'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Authenticate clients with mTLS certificates passed in headers by a WAF or load balancer'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways

icon: header-cert-auth.png

categories:
  - authentication

tags:
  - authentication

search_aliases:
  - header cert auth
  - header-cert-auth

related_resources:
  - text: "About authentication"
    url: /gateway/authentication/
  - text: CA Certificates
    url: /gateway/entities/ca-certificate/

faqs: 
  - q: Will the client need to encrypt the message with a private key and certificate when passing the certificate in the header?
    a: |
      No, the client only needs to send the target's certificate encoded in a header. {{site.base_gateway}} will validate the certificate, but it requires a high level of trust that the WAF/LB is the only entrypoint to the {{site.base_gateway}} proxy. The Header Cert Auth plugin will provide an option to secure the source, but additional layers of security are always preferable. Network level security (so that {{site.base_gateway}} only accepts requests from WAF - IP allow/deny mechanisms) and application-level security (Basic Auth or Key Auth plugins to authenticate the source first) are examples of multiple layers of security that can be applied.
      
---

The Header Cert Authentication plugin authenticates API calls by using client certificates provided in HTTP headers,
instead of relying on traditional TLS termination.
This approach is particularly useful in scenarios where TLS traffic is terminated outside of {{site.base_gateway}} such as at an external CDN or load balancer and the client certificate is passed along in an HTTP header for subsequent validation.

{:.warning}
> **Important:** To use this plugin, you must add [certificate authority (CA) Certificates](/gateway/entities/ca-certificate/). Set them up before configuring the plugin.

## How the Header Cert Auth plugin works

This plugin lets {{site.base_gateway}} authenticate API calls using client certificates received in HTTP headers, rather than through traditional TLS termination. 
This occurs in scenarios where TLS traffic is not terminated at {{site.base_gateway}}, but rather at an external CDN or load balancer, and the client certificate is preserved in an HTTP header for further validation.

The Header Cert Authentication plugin is similar to the [mTLS Auth plugin](/plugins/mtls-auth/).
However, the mTLS plugin is only designed for traditional TLS termination, while the Header Cert Auth plugin also provides support for client certificates in headers. 

The Header Cert Auth plugin extracts the client certificate from the HTTP header and validates it against the configured CA list. 
If the certificate is valid, the plugin maps the certificate to a Consumer based on the common name (CN) field.

The plugin validates the certificate provided against the configured CA list based on the
requested [Route](/gateway/entities/route/) or [Gateway Service](/gateway/entities/service/):
* If the certificate is not trusted or has expired, the response is
  `HTTP 401 TLS certificate failed verification`.
* If a valid certificate is not presented (including when requests are not sent to the HTTPS port),
  the response is `HTTP 401 No required TLS certificate was sent`.
* However, if the `config.anonymous` option is configured on the plugin,
  an [anonymous Consumer](/gateway/authentication/#using-multiple-authentication-methods) is used, and the request is allowed to proceed.

The plugin can be configured to only accept certificates from trusted IP addresses, as specified by the [`trusted_ips`](/gateway/configuration/#trusted-ips) {{site.base_gateway}} config option. This ensures that {{site.base_gateway}} can trust the header sent from the source and provides L4 level of security.

{:.warning}
> **Important:** Incomplete or improper configuration of the Header Cert Authentication plugin can compromise the security of your upstream service.
> <br><br>For instance, enabling the option to bypass origin verification can allow malicious actors to inject fake certificates, as {{site.base_gateway}} won't be able to verify the authenticity of the header. This can downgrade the security level of the plugin, making your upstream service vulnerable to attacks. Before using this plugin in production, carefully evaluate and configure the plugin according to your specific use case and security requirements.

This plugin's [static priority](/gateway/entities/plugin/#plugin-priority) is lower than all other authentication plugins, allowing other auth plugins (for example, [Basic Auth](/plugins/basic-auth/)) to secure the source first. This ensures that the source is secured by multiple layers of authentication by providing L7 level of security.

## Header size

Sending certificates in headers may exceed header size limits in some environments. 
You can configure {{site.base_gateway}} to accept larger headers by configuring the [Nginx header buffer parameter in `kong.conf`](/gateway/configuration/#nginx-http-large-client-header-buffers). 
For example:

```
nginx_proxy_large_client_header_buffers=8 24k
```

Or via an environment variable:
```
export KONG_NGINX_PROXY_LARGE_CLIENT_HEADER_BUFFERS=8 24k
```

## Client certificate request

The `send_ca_dn` option isn't supported in this plugin. This is used in mutual TLS authentication, where the server sends the list of trusted CAs to the client, and the client then uses this list to select the appropriate certificate to present. In this case, since the plugin doesn't do TLS handshakes and only parses the client certificate from the header, it isn't applicable.

The same applies to SNI functionality. The plugin can verify the certificate without needing to know the specific hostname or domain being accessed. The plugin's authentication logic is decoupled from the TLS handshake and SNI, so it doesn't need to rely on SNI to function correctly.

The format specified in the [`config.certificate_header_format`](./reference/#schema--config-certificate-header-format) parameter defines how a certificate should be passed in a request.
  * When set to `base64_encoded`, only the base64-encoded body of the certificate should be sent (excluding the `BEGIN CERTIFICATE` and `END CERTIFICATE` delimiters). 
  * When using `url_encoded`, the entire certificate, including the `BEGIN CERTIFICATE` and `END CERTIFICATE` delimiters, should be provided.

For example, given the `certificate_header_name` of x-client-cert, a `base64_encoded` example would look like the following:
```bash
x-client-cert: MIIDbDCCAdSgAwIBAgIUa...
```

A `url_encoded` example would look like the following:
```bash
x-client-cert: -----BEGIN%20CERTIFICATE-----%0AMIIDbDCCAdSgAwIBAgIUa...-----END%20CERTIFICATE-----
```

## Manual mappings between Certificate and Consumer objects

{% include_cached plugins/manual-consumer-mapping.md name=page.name slug=page.slug %}

## Troubleshooting authentication failure

When authentication fails, the client doesn't have access to any details that explain the failure. 
The security reason for this omission is to prevent malicious reconnaissance. 

Instead, the details are recorded inside [{{site.base_gateway}}'s error logs](/gateway/logs/) under the `[header-cert-auth]` filter.


