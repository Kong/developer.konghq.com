---
title: How to import a certificate object from environment variables to Kong by using the secret management function
content_type: support
description: "Export your certificate and private key as environment variables (e.g. `MY_SECRET_CERT` and `MY_SECRET_KEY`), then reference them with the `{vault://env/...}` syntax when creating a certificate object in Kong."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I import a certificate object into Kong from environment variables using the secrets management function?
  a: |
    Export the certificate and key as environment variables (e.g. `MY_SECRET_CERT` and `MY_SECRET_KEY`), then reference them in the certificate object's `cert` and `key` fields using `{vault://env/<name>}` syntax — for example, `cert: '{vault://env/my-secret-cert}'` — either in declarative config or in Kong Manager. Restart Kong afterward.
related_resources:
  - text: Kong deck sensitive data reference
    url: /deck/gateway/sensitive-data/#main
  - text: Kong Gateway secrets management documentation
    url: /gateway/secrets-management/
---

## Overview

Kong now allows you to import a certificate object from environment variables. What are the steps to implement this?

## Steps

1. Export your certificate and key as environment variables.

   Here we use `MY_SECRET_CERT` for the public certificate and `MY_SECRET_KEY` for the private key.

   ```bash
   export MY_SECRET_CERT='-----BEGIN CERTIFICATE-----
   <YOUR PUBLIC CERTIFICATE CONTENT>
   -----END CERTIFICATE-----'

   export MY_SECRET_KEY='-----BEGIN PRIVATE KEY-----
   <YOUR PRIVATE KEY CONTENT>
   -----END PRIVATE KEY-----'
   ```

2. Reference `MY_SECRET_CERT` and `MY_SECRET_KEY` to create the certificate object in Kong.

   1. If you use a declarative configuration YAML file, create the certificate object like this:

      ```yaml
      _format_version: "3.0"
      _transform: true

      certificates:
      - id: b0dbe8fd-e5e6-414a-a0dc-0160665620ab
        cert: '{vault://env/my-secret-cert}'
        key: '{vault://env/my-secret-key}'
      ```

   2. If you use Kong Manager, create the certificate object as shown below:

3. Restart Kong.

   ```bash
   kong restart
   ```
