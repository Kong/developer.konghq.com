---
title: Enable OCSP Stapling in Kong and Handle OCSP Server Downtime
content_type: support
description: Configure OCSP Stapling in Kong with the relevant NGINX environment variables, and understand how Kong behaves when the OCSP responder is unavailable.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How to Enable OCSP Stapling in Kong and Handle OCSP Server Downtime?
related_resources: []
---

## Overview

This article describes how to enable OCSP Stapling in Kong and how Kong handles OCSP server downtime.

## Steps

Enabling OCSP (Online Certificate Status Protocol) Stapling in Kong is crucial for enhancing the security of your server-client communications. OCSP Stapling allows the server to provide a timestamped OCSP response from the Certificate Authority to the client during the TLS handshake, proving the certificate's validity. This process reduces the client's need to contact the CA, improving privacy and performance.

To configure OCSP Stapling in Kong, you need to set specific environment variables in your Kong configuration. These variables are:

```shell
KONG_NGINX_PROXY_SSL_STAPLING=on
KONG_NGINX_PROXY_SSL_STAPLING_VERIFY=on
```

Additionally, to ensure the OCSP response is validated correctly, you should include the complete certificate chain of the issuer for the server certificate whose OCSP response we are validating. This can be achieved by setting the following variables:

```shell
KONG_NGINX_PROXY_SSL_TRUSTED_CERTIFICATE=
```

It's important to note that if Kong is unable to retrieve the OCSP response from the responder, it will not staple the response in the TLS handshake. However, the handshake will still succeed, and the connection will be established as expected. This behavior ensures that your service remains accessible even if the OCSP server is temporarily unavailable.
