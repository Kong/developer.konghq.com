---
title: "How to use Kong's OpenID Connect plugin to extract specific claims from JWT tokens and add them as custom headers to the request"
content_type: support
description: Configure the OpenID Connect plugin's `upstream_headers` and `downstream_access_token_header` parameters to extract specific JWT claims and add them as custom request headers to the upstream service.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: A more detailed example
    url: https://gist.github.com/ashman1984/4d6ea7367da119524747fa93821b24da
tldr:
  q: How do I use Kong's OpenID Connect plugin to extract specific claims from JWT tokens and add them as custom headers to the request?
  a: |
    Set the `upstream_headers` parameter (and `downstream_access_token_header` for bearer-token setups) on the OpenID Connect plugin to map JWT claims to custom header names, for example `- "employeeID:X-Employee-Id"`. Non-string claim values are base64-encoded automatically and must be decoded upstream, and if a claim is mapped to a header more than once only the last value wins. This lets you add custom claim-based headers without writing a custom plugin.
---

## Overview

How can I use Kong's OpenID Connect plugin to extract specific claims from JWT tokens and add them as custom headers to the request?

## Steps

To extract specific claims from JWT tokens and inject them as custom headers in requests to upstream services, follow the steps outlined below.

This solution involves configuring the OpenID Connect plugin to perform claim extraction and header addition without developing a custom plugin.

Configure the OpenID Connect Plugin:

Set the `upstream_headers` and `downstream_access_token_header` parameters in the OIDC plugin.

This configuration allows the extraction of custom claims (like `employeeID`) from JWT tokens and injecting these claims as custom headers in the requests forwarded to the upstream services.

`upstream_headers` - An array mapping token claims to the upstream header names that will carry their values, e.g. `- "employeeID:X-Employee-Id"`. (The older `upstream_headers_claims`/`upstream_headers_names` field pair is deprecated as of Kong Gateway 3.10 and slated for removal in 4.0 — it still works today, but new configurations should use the combined `upstream_headers` field instead. The equivalent combined field for the downstream/client-facing response is `downstream_headers`, replacing the older `downstream_headers_claims`/`downstream_headers_names` pair.)

`downstream_access_token_header` - The header name that contains the JWT token when a Bearer token is used

Important Considerations:

- Ensure that the JWT tokens used in testing contain the claims specified for mapping.

- Duplicate headers are not supported; the last claim value assigned to a particular header will be used.

- If the claim is an object or an array (anything other than a string), it will be base64 encoded and will need to be decoded by the upstream API/server.

Testing and Verification:

After applying the configuration, verify that the JWT claims are correctly mapped to headers in the requests sent to the upstream service. You can check the Kong logs for any errors related to JWT validation or header mapping.

By following these steps, you can leverage Kong's OpenID Connect plugin to manipulate JWT headers for extracting specific claims and adding them as custom headers in requests, without a custom plugin.

This approach simplifies the process and utilizes the built-in capabilities of the OpenID Connect plugin.

For a more detailed example, review this Gist.
