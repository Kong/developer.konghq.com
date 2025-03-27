---
title: 'Header Cert Authentication'
name: 'Header Cert Authentication'

content_type: plugin

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

search_aliases:
  - header cert auth
  - header-cert-auth
  - authentication

faqs: 
  - q: Will the client need to encrypt the message with a private key and certificate when passing the certificate in the header?
    a: |
      No, the client only needs to send the target's certificate encoded in a header. {{site.base_gateway}} will validate the certificate, but it requires a high level of trust that the WAF/LB is the only entrypoint to the {{site.base_gateway}} proxy. The Header Cert Auth plugin will provide an option to secure the source, but additional layers of security are always preferable. Network level security (so that {{site.base_gateway}} only accepts requests from WAF - IP allow/deny mechanisms) and application-level security (Basic Auth or Key Auth plugins to authenticate the source first) are examples of multiple layers of security that can be applied.
      
---

The Header Cert Authentication plugin authenticates API calls by using client certificates provided in HTTP headers,
instead of relying on traditional TLS termination.
This approach is particularly useful in scenarios where TLS traffic is terminated outside of {{site.base_gateway}} such as at an external CDN or load balancer and the client certificate is passed along in an HTTP header for subsequent validation.

{:.warning}
> **Important:** To use this plugin, you must add [certificate authority (CA) certificates](/gateway/entities/ca-certificate/). Set them up before configuring the plugin.

## How it works

This plugin lets {{site.base_gateway}} authenticate API calls using client certificates received in HTTP headers, rather than through traditional TLS termination. 
This occurs in scenarios where TLS traffic is not terminated at {{site.base_gateway}}, but rather at an external CDN or load balancer, and the client certificate is preserved in an HTTP header for further validation.

The Header Cert Authentication plugin is similar to the [mTLS Auth plugin](/plugins/mtls-auth/).
However, the mTLS plugin is only designed for traditional TLS termination, while the Header Cert Auth plugin also provides support for client certificates in headers. 

The Header Cert Auth plugin extracts the client certificate from the HTTP header and validates it against the configured CA list. 
If the certificate is valid, the plugin maps the certificate to a Consumer based on the common name (CN) field.

The plugin validates the certificate provided against the configured CA list based on the
requested Route or Gateway Service:
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
KONG_NGINX_PROXY_LARGE_CLIENT_HEADER_BUFFERS=8 24k
```

## Client certificate request

The `send_ca_dn` option is not supported in this plugin. This is used in mutual TLS authentication, where the server sends the list of trusted CAs to the client, and the client then uses this list to select the appropriate certificate to present. In this case, since the plugin doesn't do TLS handshakes and only parses the client certificate from the header, it isn't applicable.

The same applies to SNI functionality. The plugin can verify the certificate without needing to know the specific hostname or domain being accessed. The plugin's authentication logic is decoupled from the TLS handshake and SNI, so it doesn't need to rely on SNI to function correctly.

How a client certificate should be passed in a request depends on the format specified in the [`config.certificate_header_format`](./reference/#schema--config-certificate-header-format) parameter. 
  * When set to `base64_encoded`, only the base64-encoded body of the certificate should be sent (excluding the `BEGIN CERTIFICATE` and `END CERTIFICATE` delimiters). 
  * When using `url_encoded`, the entire certificate, including the `BEGIN CERTIFICATE` and `END CERTIFICATE` delimiters, should be provided.

For example, given the `certificate_header_name` of x-client-cert:

`base64_encoded`

```bash
x-client-cert: MIIDbDCCAdSgAwIBAgIUa...
```

`url_encoded`

```bash
x-client-cert: -----BEGIN%20CERTIFICATE-----%0AMIIDbDCCAdSgAwIBAgIUa...-----END%20CERTIFICATE-----
```

## Manual mappings between Certificate and Consumer objects

Sometimes, you might not want to use automatic Consumer lookup, or you have certificates
that contain a field value not directly associated with Consumer objects. In those
situations, you can manually assign one or more subject names to the [Consumer entity](/gateway/entities/consumer/) for
identifying the correct Consumer.

{:.info}
> **Note**: Subject names refer to the certificate's Subject Alternative Names (SAN) or
Common Name (CN). CN is only used if the SAN extension does not exist.

You can create a Consumer mapping with either of the following:
  * The [`/consumers/{consumer}/header-cert-auth` Admin API endpoint](/api/gateway/admin-ee/#/operations/create-plugin-for-consumer)
  * [decK](/gateway/entities/consumer/#set-up-a-consumer) by specifying `header_cert_auth_credentials` in the configuration like the following:
    
    ```yaml
    consumers:
    - custom_id: my-consumer
      username: {consumer}
      header_cert_auth_credentials:
      - id: bda09448-3b10-4da7-a83b-2a8ba6021f0c
        subject_name: test@example.com
    ```

The following table describes how Consumer mapping parameters work for the Header Cert Auth plugin:

{% table %}
columns:
  - title: Form Parameter
    key: parameter
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - parameter: "`id`<br>*required for declarative config*"
    default: none
    description: "UUID of the Consumer mapping. Required if adding mapping using declarative configuration, otherwise generated automatically by {{site.base_gateway}}'s Admin API."
  - parameter: "`subject_name`<br>*required*"
    default: none
    description: "The Subject Alternative Name (SAN) or Common Name (CN) that should be mapped to `consumer` (in order of lookup)."
  - parameter: "`ca_certificate`<br>*optional*"
    default: none
    description: "**If using the Admin API:** UUID of the Certificate Authority (CA). <br><br> **If using declarative configuration:** Full PEM-encoded CA certificate. <br><br>The provided CA UUID or full certificate has to be verifiable by the issuing certificate authority for the mapping to succeed. This is to help distinguish multiple certificates with the same subject name that are issued under different CAs. <br><br>If empty, the subject name matches certificates issued by any CA under the corresponding `config.ca_certificates`."
{% endtable %}

### Matching behaviors

After a client certificate has been verified as valid, the Consumer object is determined in the following order, unless [`config.skip_consumer_lookup`](./reference/#schema--config-skip-consumer-lookup) is set to `true`:

1. Manual mappings with `subject_name` matching the certificate's SAN or CN (in that order) and `ca_certificate = {issuing authority of the client certificate}`
2. Manual mappings with `subject_name` matching the certificate's SAN or CN (in that order) and `ca_certificate = NULL`
3. If [`config.consumer_by`](./reference/#schema--config.consumer_by) is not null, Consumer with `username` and/or `id` matching the certificate's SAN or CN (in that order)
4. The [`config.anonymous`](./reference/#schema--config-anonymous) Consumer (if set)

{:.info}
> **Note**: Matching stops as soon as the first successful match is found.

### Upstream headers
{% include_cached /plugins/upstream-headers.md %}

When `skip_consumer_lookup` is set to `true`, Consumer lookup is skipped and instead of appending aforementioned headers, the plugin appends the following two headers

* `X-Client-Cert-Dn`: The distinguished name of the client certificate
* `X-Client-Cert-San`: The SAN of the client certificate

Once `config.skip_consumer_lookup` is applied, any client with a valid certificate can access the Service/API.
To restrict usage to only some of the authenticated users, also add the [ACL plugin](/plugins/acl/) and create
allowed or denied groups of users using the same
certificate property being set in `config.authenticated_group_by`.

## Troubleshooting authentication failure

When authentication fails, the client doesn't have access to any details that explain the failure. The security reason for this omission is to prevent malicious reconnaissance. Instead, the details are recorded inside [{{site.base_gateway}}'s error logs](/gateway/logs/) under the `[header-cert-auth]` filter.


