---
title: "\"SSL_do_handshake() failed (SSL: error:XXXXXXSSL routines::bad key share)\" errors in Kong logs"
content_type: support
description: "The `SSL_do_handshake()` bad key share errors are typically caused by outdated clients or by network probes, and are usually benign background noise when Kong is exposed to the internet."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: "What are the \"SSL_do_handshake() failed (SSL: error:XXXXXXSSL routines::bad key share)\" errors in my Kong logs?"
  a: |
    These handshake errors come from clients using outdated SSL/TLS software or from network probes and scanners hitting an internet-exposed Kong.
    They're usually benign background noise and can be ignored unless they coincide with real user-facing disruption.
related_resources: []
---

## Problem

Kong logs show "SSL_do_handshake() failed (SSL: error:XXXXXXSSL routines::bad key share)" errors.

## Cause

The "SSL_do_handshake() failed (SSL: error:XXXXXXSSL routines::bad key share)" error typically occurs under two circumstances:

```
1. The client attempting to connect to Kong is using outdated software that does not
 properly implement current SSL/TLS protocols or ciphers.

2. Network probes or scanners are targeting the Kong instance, attempting network 
penetration tests on exposed network endpoints.
```

In scenarios where your Kong instance is exposed to the internet, encountering such errors in the logs can be common. These errors are often the result of automated scans or probes rather than legitimate traffic. Unless these errors are accompanied by reports of disruption from legitimate users or noticeable impact on normal traffic flow, they can generally be considered benign and ignored.

```
Error Log Example:
2024/06/21 04:47:54 [crit] 209699#0: *95789 SSL_do_handshake() failed (SSL: error:0A00006C:SSL routines::bad key share) while SSL handshaking, client: 172.168.40.219, server: 0.0.0.0:8443
```

## Solution

It's important to monitor your logs for any patterns that might suggest a more serious issue or if these errors start occurring with a higher frequency. Regularly updating client software and maintaining a secure and updated Kong environment can also mitigate the occurrence of such errors.

In summary, if these errors do not coincide with actual service disruptions or complaints from end-users, they can be safely ignored as noise from internet background radiation.

However, always ensure your systems are up-to-date and monitor for any unusual patterns in your logs that could indicate a more serious issue.
