---
title: "Kong Gateway: 401 HTTP response and \"unable to verify digest\" error seen after updating signing certificate in IdP"
content_type: support
description: "When the Kong OIDC plugin throws a 401 error following an update to the IDP signer certificate, it is typically due to the plugin's cache not being updated with the new certificate information."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the Kong OIDC plugin return an HTTP 401 with an "unable to verify digest" error after the IdP's signing certificate is updated?
  a: |
    The plugin's cache isn't refreshed because the JWKS `kid` (Key ID) didn't change even though the signing certificate did, so the cache has no signal to recrawl. Short-term, disable and re-enable the plugin (or clear the cache via the `/openid-connect/issuers` endpoint) to force a recrawl. Long-term, use dynamic JWKS `kid` values instead of static ones so client-side caches refresh automatically.
related_resources: []
---

## Problem

We are using the Kong OpenID Connect (openid-connect / OIDC) plugin. We use extra JWKS URLs and recently the IdPs signing certificate was updated. We are now observing the following error in our logs with failed requests (HTTP 401 responses):

```

2023/09/19 04:59:59 [notice] 26170#0: *7857901 [lua] responses.lua:21: [openid-connect] unable to RSA SHA512 verify digest, client: {ipAddress}, server: kong, request: "POST {URI} HTTP/1.1", host: "{hostname}"
```

What does this error mean and why are we seeing this, how can we resolve this issue?

## Solution

When the Kong OIDC plugin throws a 401 error following an update to the IDP signer certificate, it is typically due to the plugin's cache not being updated with the new certificate information. This can happen when the `kid` (Key ID) in the JWKS (JSON Web Key Set) does not change even though the signing certificate has been updated. The OIDC plugin's cache expects either a new `kid` or a new issuer to trigger a recrawl of the JWKS endpoint.

There is a short-term and long-term solution to this issue below:

1. The short-term solution is to disable and re-enable the plugin, this will force a cache rebuild and allow the {{site.base_gateway}} to recrawl for the latest JWKS. If there are many instances of this plugin affected, then the quickest method will be to delete the cache system-wide with either a restart of the node or a cURL command to the `/openid-connect/issuers` API endpoint. An example request to that endpoint: `curl -X DELETE http://<admin-hostname>:8001/openid-connect/issuers`
2. The long-term solution is to discontinue use of static key IDs. Although employing static `kid` values in the JSON Web Key Set (JWKS) is allowed, it introduces challenges and is not aligned with industry-recommended practices. The preferred strategy is using dynamic `kid` values as they are automatically rotated to a different value when the signing certificate or other relevant details are updated. This approach not only enhances security but also ensures automatic refreshment of client-side caching without manual intervention. If you continue to use static `kid` values, then you will need to incorporate the cache clearing steps above in step 1 into your process whenever the JWKS are modified or signing certificates are changed.
