---
title: Store certificates in Konnect Config Store
content_type: how_to
related_resources:
  - text: Secrets management
    url: /secrets-management/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: Configure the Konnect Config Store
    url: /how-to/configure-the-konnect-config-store/
  - text: Store a Mistral API key as a secret in Konnect Config Store
    url: /how-to/store-a-mistral-api-key-as-a-secret-in-konnect-config-store/
  - text: Reference secrets stored in the Konnect Config Store
    url: /how-to/reference-secrets-from-konnect-config-store/

products:
    - gateway

works_on:
    - konnect

entities: 
  - vault

tags:
    - security
    - secrets-management

tldr:
    q: How do I securely replace my {{site.base_gateway}} data plane node certificates with a secret reference instead?
    a: placeholder

prereqs:
  inline:
    - title: Konnect API
      include_content: prereqs/konnect-api-for-curl

tools:
  - konnect-api
 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

@todo

Use content from https://docs.konghq.com/konnect/gateway-manager/configuration/vaults/how-to/

1. Prereqs: Create a cert: (OR! https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/secure-communications/#generate-certificates-in-konnect)
  Create an SSL certificate

  1. Generate a private key

      ```sh
      openssl genpkey -algorithm RSA -out my-key.pem
      ```
  2. Generate a certificate signing request

      ```
      openssl req -new -key my-key.pem -out my-csr.pem
      ```
  3. Create a self-signed certificate 

      ```
      openssl x509 -req -in my-csr.pem -signkey my-key.pem -out my-cert.pem -days 365
      ```

  4. Create a UUID using the shell: 

      ```
      uuidgen
      ```

1. Enable Config Store
1. Create a Config Store vault
1. Configure cert and key as secrets in the vault
1. Reference the secrets in the Certificate entity
1. Validate ideas:
  * https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/verify-node/#access-services-using-the-proxy-url
  If you can hit the proxy, it's configured correctly.