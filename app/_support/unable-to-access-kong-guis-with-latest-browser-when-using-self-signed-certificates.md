---
title: "Unable to access Kong GUIs with latest browsers when using self-signed certificates"
content_type: support
description: Browsers require accepting a self-signed certificate warning separately for Kong Manager, the Admin API, and the Proxy before the UI will load.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why do I have to accept a self-signed certificate warning separately for Kong Manager, the Admin API, and the Proxy?
  a: |
    This is expected browser behavior, not unique to Kong. Install a local CA certificate for your browser, or accept the self-signed certificate once per endpoint (Kong Proxy on 8000, Admin API on 8001), to avoid repeating the warning. Kong recommends a trusted CA certificate for production environments.
---

## Problem

I am unable to securely login to Kong Manager with Chrome or Firefox browsers without first accessing either the Admin API or Proxy endpoints to first accept the Self Signed certificate warning. After that I can continue working with the Admin Portal until I close down the browser.

## Solution

This is not unique to Kong. This is the expected behavior of the browsers. It would also impact our Development Portal UI and tools like cURL and HTTPie.

Workaround: You should install a local CA certificate for your browsers to always work without needing to accept the self-signed certificates from either the Kong Proxy (8000) or Admin API (8001) endpoints

Here are some useful articles on how to to configure your local machine to avoid this behavior with self-signed certificates.

- https://support.mozilla.org/en-US/kb/setting-certificate-authorities-firefox
- https://medium.com/@tbusser/creating-a-browser-trusted-self-signed-ssl-certificate-2709ce

Note: Kong recommends using a trusted CA SSL certificate for Kong Production environments.
