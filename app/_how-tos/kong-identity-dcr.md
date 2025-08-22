---
title: Automatically create Dev Portal applications in Kong Identity with Dynamic Client Registration
description: Learn how to configure Dynamic Client Registration to automatically create Dev Portal applications in Kong Identity.
content_type: how_to

products:
    - gateway
    - dev-portal

works_on:
    - konnect
entities: []

automated_tests: false

tags:
    - dynamic-client-registration
    - application-registration
    - openid-connect
    - authentication
    - okta
search_aliases:
    - dcr
    - OpenID Connect

tldr:
    q: How do I automatically create and manage Dev Portal applications in Kong Identity?
    a: |
      You can use Dynamic Client Registration to automatically create Dev Portal applications in Kong Identity. First, create scopes and claims in Kong Identity and copy your Issuer URL. Then, create a new DCR provider in your Dev Portal settings and create a new auth strategy for DCR.

prereqs:
  inline:
    - title: Dev Portal
      include_content: prereqs/dev-portal-app-reg
      icon_url: /assets/icons/dev-portal.svg
related_resources:
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: About Dev Portal Dynamic Client Registration
    url: /dev-portal/dynamic-client-registration/
  - text: About Dev Portal OIDC authentication
    url: /dev-portal/auth-strategies/#dev-portal-oidc-authentication
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

{% include /how-tos/steps/konnect-identity-server-scope-claim-client.md %}

## Configure the Kong Identity Dynamic Client Registration in Dev Portal

After configuring Kong Identity, you can integrate it with the Dev Portal for Dynamic Client Registration (DCR). This process involves two main steps: first, creating the DCR provider, and second, establishing the authentication strategy. DCR providers are designed to be reusable configurations. This means once you've configured the Kong Identity DCR provider, it can be used across multiple authentication strategies without needing to be set up again.

Configure Kong Identity as a DCR provider:
<!--vale off-->
{% konnect_api_request %}
url: /v2/dcr-providers
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Kong Identity"
  provider_type: "kong"
  issuer: "'$ISSUER_URL'"
  dcr_config:
    dcr_token: "?"
{% endkonnect_api_request %}
<!--vale on-->

Export your DCR provider ID:
```sh
export DCR_PROVIDER='YOUR-KONG-IDENTITY-DCR-ID'
```

Create a Kong Identity authentication strategy:
<!--vale off-->
{% konnect_api_request %}
url: /v2/application-auth-strategies
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Kong Identity"
  display_name: "Kong Identity"
  strategy_type: "openid_connect"
  configs:
    openid-connect:
        issuer: "'$ISSUER_URL'"
        credential_claim:
        - client_id
        scopes:
        - my-scope
        auth_methods:
        - client_credentials
        - bearer
  dcr_provider_id: "'$DCR_PROVIDER'"
{% endkonnect_api_request %}
<!--vale on-->


## Apply the Kong Identity DCR auth strategy to an API

Now that the application auth strategy is configured, you can apply it to an API.

1. Navigate to your Dev Portal in {{site.konnect_short_name}} and click **Published APIs** in the sidebar.

1. Click **Publish API**, select the API you want to publish, and select your Kong Identity auth strategy for the **Authentication strategy**.

1. Click **Publish API**.

## Validate

{% include konnect/dcr-validate.md %}
