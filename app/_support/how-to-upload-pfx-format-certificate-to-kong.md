---
title: How to upload a PFX-format certificate to Kong
content_type: support
description: Convert a PFX certificate to separate PEM certificate and key files, then upload them to Kong via Kong Manager or the Admin API.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Certificate entity - set up a certificate
    url: /gateway/entities/certificate/#set-up-a-certificate
tldr:
  q: How do I upload a PFX-format certificate to Kong?
  a: |
    Kong's Certificate entity only accepts PEM-format certificates and keys, so convert the `.pfx` file with `openssl pkcs12` into separate `key.pem` and `cert.pem` files first (stripping any `Bag Attributes` / `Key Attributes` headers). Then upload both files to Kong as a Certificate entity, either through Kong Manager or the Admin API `/certificates` endpoint.
---

## Overview

How to upload a `pfx` format certificate to kong?

## Steps

1. Convert a PFX file to separate certificate and private key PEM files:

   ```bash
   openssl pkcs12 -in <pfx file> -nocerts -out key.pem -nodes
   openssl pkcs12 -in <pfx file> -nokeys -out cert.pem
   ```

2. Remove `Bag Attributes`, `Key Attributes` and any other attributes from `key.pem` and `cert.pem`.

   Make sure `key.pem` is in the format below:

   ```
   -----BEGIN PRIVATE KEY-----
   xxxxxxxxxxxxxxxxxxxx
   -----END PRIVATE KEY-----
   ```

   Make sure `cert.pem` is in the format below:

   ```
   -----BEGIN CERTIFICATE-----
   yyyyyyyyyyyyyyy
   -----END CERTIFICATE-----
   ```

   If you are using intermediate certificates, `cert.pem` should be in the format below instead:

   ```
   -----BEGIN CERTIFICATE-----
   <SERVER_CERTIFICATE>
   -----END CERTIFICATE-----
   -----BEGIN CERTIFICATE-----
   <INTERMEDIATE_CERTIFICATE>
   -----END CERTIFICATE-----
   ...
   ```

3. Upload `key.pem` and `cert.pem` to Kong via Kong Manager or the Admin API:

   1. Upload using Kong Manager:

      Access `http://<kong>:8002/<workspace>/certificates/create`,
      copy the content from `cert.pem` to the "Cert" input box,
      copy the content from `key.pem` to the "Key" input box,
      then click the "Create" button.

   2. Upload using the Admin API below:

      ```bash
      curl -X POST http://<kong>:8001/<workspace>/certificates \
      -F cert=@/path/to/cert.pem \
      -F key=@/path/to/key.pem
      ```

Check more details in the Certificate entity - set up a certificate documentation.
