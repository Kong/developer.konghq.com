---
title: Kong Gateway is unable to create a session after successfully authenticating a user
content_type: support
description: "Kong Manager or the Dev Portal can fail to create a session, with the browser rejecting the session cookie for an invalid domain, when the host domain is on the Mozilla Public Suffix List. Use a more narrowly scoped domain or private DNS to work around it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Public Suffix List
    url: https://publicsuffix.org/list/public_suffix_list.dat
tldr:
  q: Why is Kong Manager or the Developer Portal rejecting the session cookie after a successful login?
  a: |
    The browser rejects the session cookie with an invalid-domain error when the host domain (or a suffix of it) is listed on the Mozilla Public Suffix List — a list used to prevent cookies from being scoped to shared, high-level domain suffixes like `*.com` or `com.au`. Work around it by using a more narrowly scoped domain where feasible, or by using private DNS.
---

## Problem

Attempts to login to Kong Manager/Portal are failing, however no message is displayed in the GUI indicating an error. The user ID and password have been confirmed to be valid and only when inspecting the messages in the browser developer tools can a problem be seen.

Firefox (console tab): You can see that the session cookie is being rejected with the message: `Cookie "<cookie-name>" has been rejected for invalid domain`

Chrome/Edge (network tab): Indicated on the response header by the yellow icon. `This attempt to set a cookie via a Set-Cookie header was blocked because its Domain attribute was invalid with regards to the current host URL.`

## Solution

This can occur when you are trying to set a cookie using a domain listed on the Mozilla Public Suffix List. This list is used to limit the scope of the cookie being set to avoid issues like setting a "supercookie" for high level domain suffixes.

For example, you cannot set a cookie for `*.com` as it would apply to any website hosted on this TLD.

To correct this issue for second-level domains (i.e., `com.au`) in a unified way, Mozilla created the Public Suffix List.

This list is used to determine where cookies may and may not be set. Domains on the list are restricted and will result in these errors.

To resolve this you would need to either

- Use a more narrowly scoped domain, where feasible
- Use private DNS
