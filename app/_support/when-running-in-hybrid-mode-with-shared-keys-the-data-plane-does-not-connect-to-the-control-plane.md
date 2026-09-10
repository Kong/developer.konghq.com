---
title: When running in hybrid mode with shared keys, the Data Plane does not connect to the Control Plane
content_type: support
description: In hybrid shared mode, the certificates must have a common name of `kong_clustering`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does the data plane not connect to the control plane when running in hybrid mode with shared keys?
  a: |
    Hybrid mode with shared certificates requires the certificate's common name to be `kong_clustering`. Certificates generated with plain `openssl` (instead of `kong hybrid gen_cert`) commonly use the wrong common name, which causes a `tls handshake failed: certificate host mismatch` error on the data plane. Regenerate the certificate with `-subj "/CN=kong_clustering"` to fix it.
related_resources: []
---

## Problem

After setting up a hybrid instance, using shared certificates, the data planes do not get the configuration updated from the control plane. Checking the data plane logs, there is an error for the TLS handshake failing (`tls handshake failed: certificate host mismatch`).

```
connection to control plane wss://10.0.10.1:8005/v1/outlet?node_id=4a8198f6-494e-4a94-8a3c-a34b8705c2da&node_hostname=dataplane-kong-enterprise-fda26afc40-46ed2&node_version=3.14.0.0-enterprise-edition broken: tls handshake failed: certificate host mismatch (retrying after 10 seconds), context: ngx.timer
```

The shared certificates were generated using `openssl` and not the `kong hybrid gen_cert` command.

## Cause

In hybrid shared mode, the certificates must have a common name of `kong_clustering`. If the certificates use a different common name, then you will see the host mismatch error.

## Solution

You can generate certificates with the correct format with an `openssl` command like this:

```bash
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout /tmp/cluster.key -out /tmp/cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
```
