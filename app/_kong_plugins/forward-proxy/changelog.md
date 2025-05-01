---
content_type: reference
---

## Changelog

### {{site.base_gateway}} 3.10.x
* Fixed an issue where the `upstream_status` field was empty in logs when using the `forward-proxy` plugin.

### {{site.base_gateway}} 3.6.x
* The plugin now falls back to the non-streaming proxy when the request body was already read.
* Fixed an issue where request payload was discarded when the payload exceeded the `client_body_buffer_size`.

### {{site.base_gateway}} 3.1.x

* `x_headers` field added. This field indicates how the plugin handles the headers
  `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Forwarded-Host`, and `X-Forwarded-Port`.

  The field is set to `append` by default, but can be set to one of the following options:
  * `append`: Append information from this hop to the headers.
  * `transparent`: Leave headers unchanged, as if not using a proxy.
  * `delete`: Remove all headers including those that should be added for this hop, as if you are the originating client.

  Note that all options respect the trusted IP setting, and will ignore last hop headers if they are not from clients with trusted IPs.

### {{site.base_gateway}} 3.0.x
Fixed a proxy authentication error caused by incorrect base64 encoding.
  * Use lowercase when overwriting the Nginx request host header.
  * The plugin now allows multi-value response headers.

### {{site.base_gateway}} 2.8.x

* Added `http_proxy_host`, `http_proxy_port`, `https_proxy_host`, and
`https_proxy_port` configuration parameters for mTLS support.

    {:.warning}
    > These parameters replace the `proxy_port` and `proxy_host` fields, which
    are now **deprecated** and planned to be removed in a future release.

* The `auth_password` and `auth_username` configuration fields are now marked as
referenceable, which means they can be securely stored as
[secrets](/gateway/secrets-management/)
in a vault. References must follow a [specific format](/gateway/entities/vault/#how-do-i-reference-secrets-stored-in-a-vault).
* Fixed an issue which occurred when receiving an HTTP `408` from the upstream through a forward proxy. 
  Nginx exited the process with this code, which resulted in Nginx ending the request without any contents.
* If the `https_proxy` configuration parameter is not set, it now defaults to `http_proxy` to avoid DNS errors.
Fixed an `invalid header value` error for HTTPS requests. The plugin
  now accepts multi-value response headers.
* Fixed an error where basic authentication headers containing the `=`
character weren't forwarded.
* Use lowercase when overwriting the `host` header

### {{site.base_gateway}} 2.7.x

* Added `auth_username` and `auth_password` parameters for proxy authentication.
