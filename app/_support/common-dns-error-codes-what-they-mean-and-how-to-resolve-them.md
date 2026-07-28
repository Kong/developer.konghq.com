---
title: Common DNS Error Codes - What They Mean and How To Resolve Them
content_type: support
description: "It's important to understand that any DNS error codes lower than 100 are returned by the DNS servers themselves, and any error codes greater than 100 are returned by the DNS client."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: What do common Kong DNS error codes (SERVFAIL, NXDOMAIN, REFUSED) mean, and how do I resolve them?
  a: |
    DNS error codes below 100 are returned by the DNS server itself; codes above 100 are returned by the DNS client. `SERVFAIL` (code 2) means the DNS server failed to process the request — engage your DNS admins, since only server-side logs explain the failure. `NXDOMAIN` (code 3) means the record doesn't exist — first check for typos in the hostnames configured on Kong's services and upstreams, then have the DNS admins add the missing record. `REFUSED` (code 5) means the DNS server rejected the request, often for policy or rate-limit reasons — engage your DNS admins to investigate.
---

## Problem

There are many different DNS-related error codes in Kong, and this article will address the most common ones observed. Specifically, the error codes we'll be addressing are as follows:

- DNS error code 2: Server Failure (SERVFAIL)

  ```
  DNS resolution failed: dns server error: 2 server failure. Tried: [...] - cache-hit/dns server error: 2 server failure
  ```

- DNS error code 3: Name Error (NXDOMAIN)

  ```
  DNS resolution failed: dns server error: 3 name error. Tried: [...] - cache-hit/dns server error: 3 name error
  ```

- DNS error code 5: REFUSED

  ```
  cache-hit/dns server error: 5 refused
  ```

## Solution

It's important to understand that any DNS error codes lower than 100 are returned by the DNS servers themselves, and any error codes greater than 100 are returned by the DNS client.

The explanation and solution to the various DNS errors depends, of course, on the specific DNS error code encountered, so be sure to follow the instructions below based on the error code observed in the Kong logs.

DNS error code #2: Server Fail (SERVFAIL):

- This means the DNS server failed to process the DNS request. It's unclear why that would fail, but only the DNS server logs would indicate why it's failing to process the DNS request, and this is not something that can be understood from Kong's side.
- The next action should be to engage the DNS server admins to look into this response code further.

DNS error code #3: Name Error (NXDOMAIN):

- This error means that Kong was able to successfully communicate with the DNS server and made its request, but the DNS server responded to Kong saying "I don't have that domain record in my system". This means the DNS record doesn't exist. It's a DNS server-side error and not a Kong error.
- The next action should be done in this order:

  1. Ensure there is no typo in the hostname(s) on the Kong side, checking that all services and upstreams are correctly written.
  2. If step 1 above is validated and there were no typos on Kong's side, engage the DNS server admins to look into this response code further and ensure they add the correct DNS records so they can be found by any DNS clients looking for the record which was failing earlier. Ensure there are no typos in the DNS records too.

DNS error code #5: Refused (REFUSED):

- This error implies that the DNS server received the request but refused it for unknown reasons. Much like error code #2, the reason why the request was refused will only be known to the DNS server and found in the DNS server logs; it is not something that can be understood from Kong's side. Usually this is due to policy reasons such as a block for the DNS client or exceeding a rate limit threshold.
- The next action should be to engage the DNS server admins to look into this response code further.
