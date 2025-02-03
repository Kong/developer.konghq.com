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

1. Prereqs: Create a cert (new data plane node?): https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/secure-communications/#generate-certificates-in-konnect)

1. Create a env vault
{% entity_example %}
type: vault
data:
  name: env
  prefix: my-vault
  description: Storing secrets in an environment variable vault
{% endentity_example %}
1. Configure cert and key as env secrets ON THE DATA PLANE NODE!
  ```
  export MY_SECRET_CERT="<cert data>" \
  export MY_SECRET_KEY="<key data>"
  ```
1. Restart the data plane node to load the values.
`kong restart`?
1. Reference the secrets in the DP Certificate entity
https://docs.konghq.com/konnect/api/control-plane-configuration/latest/#/DP%20Certificates/create-dataplane-certificate 

{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/dp-client-certificates
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    cert: "{vault://env/my-secret-cert}"
{% endcontrol_plane_request %}

1. Validate ideas:
  * https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/verify-node/#access-services-using-the-proxy-url
  If you can hit the proxy, it's configured correctly.