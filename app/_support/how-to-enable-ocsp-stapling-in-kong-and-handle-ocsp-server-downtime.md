---
title: Enable OCSP stapling and handle OCSP server downtime
content_type: support
description: Configure OCSP Stapling in {{site.base_gateway}} with the relevant NGINX environment variables, and understand how {{site.base_gateway}} behaves when the OCSP responder is unavailable.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I Enable OCSP Stapling and Handle OCSP Server Downtime?
  a: |
    Set `KONG_NGINX_PROXY_SSL_STAPLING=on`, `KONG_NGINX_PROXY_SSL_STAPLING_VERIFY=on`, and `KONG_NGINX_PROXY_SSL_TRUSTED_CERTIFICATE` to the issuer certificate chain.
    If the OCSP responder is unavailable, {{site.base_gateway}} skips stapling but the TLS handshake still succeeds.
related_resources: []
---

## Steps

Enabling OCSP (Online Certificate Status Protocol) Stapling in {{site.base_gateway}} is crucial for enhancing the security of your server-client communications. 
OCSP Stapling allows the server to provide a timestamped OCSP response from the Certificate Authority to the client during the TLS handshake, proving the certificate's validity. 
This process reduces the client's need to contact the CA, improving privacy and performance.

To configure OCSP Stapling in {{site.base_gateway}}, you need to set specific environment variables in your {{site.base_gateway}} configuration. These variables are:

```shell
KONG_NGINX_PROXY_SSL_STAPLING=on
KONG_NGINX_PROXY_SSL_STAPLING_VERIFY=on
```

Additionally, to ensure the OCSP response is validated correctly, you should include the complete certificate chain of the issuer for the server certificate whose OCSP response we are validating. This can be achieved by setting the following variables:

```shell
KONG_NGINX_PROXY_SSL_TRUSTED_CERTIFICATE=/path/to/issuer-ca-chain.pem
```

It's important to note that if Kong is unable to retrieve the OCSP response from the responder, it will not staple the response in the TLS handshake. However, the handshake will still succeed, and the connection will be established as expected. This behavior ensures that your service remains accessible even if the OCSP server is temporarily unavailable.
