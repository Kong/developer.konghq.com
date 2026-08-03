---
title: How `tls_verify_depth` works during upstream TLS verification
content_type: support
description: "`tls_verify_depth` controls how many levels of the upstream TLS certificate chain Kong verifies, from the server certificate up to the root CA."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How does `tls_verify_depth` work?
  a: |
    `tls_verify_depth` sets how many levels of the upstream certificate chain Kong walks, starting from the server certificate up toward the root CA.
    Set it to the number of links between the server cert and the root: `1` for a cert signed directly by the root, `2` for one intermediate, `3` for two intermediates. Too low a value can fail verification even on a valid chain.
related_resources: []
---

## Problem

The possible values for the `tls_verify_depth` configuration item in Kong, and the significance of each value during TLS validation with an upstream endpoint, are not obvious.

## Solution

The `tls_verify_depth` setting in Kong is crucial for the TLS certificate verification process when communicating with an upstream endpoint. This setting determines how many levels in the certificate chain Kong will verify to establish the authenticity of the certificate presented by the upstream server. Understanding and configuring this setting correctly is essential to ensure secure and successful TLS connections.

The verification process starts from the end-entity (server) certificate and moves up towards the root certificate. The value of `tls_verify_depth` indicates how many steps Kong will take up this chain. If the value is set too low, Kong might not reach the root certificate, potentially leading to failed verifications even if the certificate chain is valid. Here are examples to illustrate how to set this value based on different scenarios:

Example 1: Directly Signed by Root CA

If a server's certificate is directly signed by a root CA, the chain looks like this:

```
Root CA
|
Server Certificate
```

In this scenario, you would set `tls_verify_depth` to `1`, because the server certificate is directly under the root certificate.

Example 2: Signed by an Intermediate CA

A more common scenario involves the server certificate being signed by an intermediate certificate, which in turn is signed by the root CA:

```
Root CA
|
Intermediate CA
|
Server Certificate
```

Here, you'd set `tls_verify_depth` to `2` to allow verification up through the intermediate to the root certificate.

Example 3: Multiple Intermediate Certificates

Sometimes, there might be multiple intermediate certificates in the chain:

```
Root CA
|
Intermediate CA 1
|
Intermediate CA 2
|
Server Certificate
```

In such cases, you might use `tls_verify_depth = 3` to ensure the entire chain can be verified.

Setting the `tls_verify_depth` appropriately is vital for mitigating certificate-based DoS attacks and ensuring the security of TLS connections. It should reflect the correct depth for the provided certificate chain to the upstream service.
