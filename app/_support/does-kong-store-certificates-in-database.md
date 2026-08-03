---
title: Certificate and key storage in Kong (disk vs. database)
content_type: support
description: "The certificates and keys specified in `kong.conf` only ever reside on disk."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
published: false
tldr:
  q: Does Kong store certificates in the database?
  a: |
    No, certificates and keys set in `kong.conf` are loaded into memory from disk and are never copied to the database. Only SNI and Certificate objects created through the Admin API are stored in the database (and cached in memory) so Kong can load them dynamically per request.
---

## Certificate and key storage in Kong

The certificates and keys specified in `kong.conf` only ever reside on disk. They are not copied into the database. Kong generates an NGINX configuration file from a template, and the generated configuration includes standard NGINX directives for loading certificates, which are loaded into memory when Kong starts. SNI and Certificate objects created through the Admin API are stored in the database, and will be stored in Kong's database cache (also in memory, though a different segment than the certificates above) after they are loaded. Kong loads these objects dynamically when it receives a request that requires them.
