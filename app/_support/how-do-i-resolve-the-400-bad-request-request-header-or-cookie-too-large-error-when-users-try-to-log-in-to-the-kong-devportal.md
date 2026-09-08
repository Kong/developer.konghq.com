---
title: HTTP 400 "Request Header Or Cookie Too Large" error when logging in to the Kong Developer Portal with Azure AD SSO
content_type: support
description: "Why an Nginx `400 Bad Request - Request Header Or Cookie Too Large` error can occur when users log in to the Kong Developer Portal or Kong Manager via Azure AD SSO, and how to increase Nginx's header buffer size to fix it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "How do I resolve the \"400 Bad Request - Request Header Or Cookie Too Large\" error when users try to log in to the Kong DevPortal?"
  a: |
    The `400 Bad Request - Request Header Or Cookie Too Large` error usually comes from an oversized Azure AD SSO token or cookie (large claims/group memberships) exceeding Nginx's default header buffer size. Fix it by setting `nginx_http_large_client_header_buffers` to a higher value (for example `"8 24k"`) in your Kong configuration.
related_resources: []
---

## Problem

Users see a "400 Bad Request - Request Header Or Cookie Too Large" error when trying to log in to the Kong Developer Portal with Azure AD SSO integration.

## Cause

This error typically occurs due to the size of the tokens returned by Azure AD, especially when the tokens include a large number of claims or group memberships. By default, Nginx uses 4 buffers of 8k each to read the request headers.

This is not specific to the Developer Portal — the same fix applies to Kong Manager's own OpenID Connect admin login (`admin_gui_auth=openid-connect`) or any other Kong-fronted application hitting this class of error with a large SSO cookie/token. Note also that the on-prem/Gateway-native Developer Portal is deprecated on standard Enterprise licenses as of Kong Gateway 3.11.0.0+ (its Admin API routes return `404` without a separate license entitlement); if you cannot reach the Developer Portal login page at all, confirm your license's Developer Portal entitlement before assuming this buffer-size issue is the cause.

## Solution

The issue of receiving a "400 Bad Request - Request Header Or Cookie Too Large" error when users attempt to log in to the Kong Developer Portal, integrated with Azure AD for SSO, can be resolved by adjusting the Nginx configuration to increase the size of the buffers that read the request headers.

To address this issue, you need to modify the `nginx_http_large_client_header_buffers` setting in your Kong configuration. Increasing the number and size of these buffers can help accommodate larger tokens.

Here are the steps to adjust this setting:

1. Locate your Kong configuration file, often found in your Kong Helm chart under the `values.yaml` file, specifically under the `env:` section.

2. Add or update the `nginx_http_large_client_header_buffers` setting with a higher value. For example, to set 8 buffers of 24k each, you would add the following line:

```yaml

nginx_http_large_client_header_buffers: "8 24k"
```

3. After making this change, apply the updated configuration to your Kong deployment. The specific steps to do this will depend on how Kong is deployed in your environment (e.g., using Helm to update a Kubernetes deployment).

This adjustment should resolve the "400 Bad Request" error by allowing Nginx to handle larger request headers, including those with extensive tokens returned by Azure AD.

Additionally, if you encounter issues with users logging out and receiving an error related to a long query string ("AADSTS90015: Requested query string is too long"), this suggests that the `id_token_hint` in the logout request is too large. This can occur when the `id_token` includes a significant number of group memberships. In such cases, consider reducing the number of groups included in the token by adjusting the token configuration in Azure AD or consulting with Microsoft for further assistance on filtering claims from the `id_token`.

Remember, these adjustments are specific to the Kong Developer Portal and its integration with Azure AD for SSO. They are aimed at addressing issues related to large request headers and query strings that can occur in this context.
