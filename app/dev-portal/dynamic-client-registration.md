---
title: Dev Portal Dynamic Client Registration
content_type: reference
layout: reference

products:
    - dev-portal

breadcrumbs: 
  - /dev-portal/
tags:
  - dynamic-client-registration
  - authentication

works_on:
    - konnect
search_aliases:
  - dcr
  - oidc
description: | 
    Describes supported DCR identity providers and supported DCR authentication methods. 
related_resources:
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: Configure Dynamic Client Registration with Okta
    url: /how-to/okta-dcr/
  - text: Configure Dynamic Client Registration with Curity
    url: /how-to/curity-dcr/
  - text: Configure Dynamic Client Registration with Auth0
    url: /how-to/auth0-dcr/
  - text: Configure Dynamic Client Registration with Azure
    url: /how-to/azure-dcr/
  - text: Configure Dynamic Client Registration with Kong Identity
    url: /how-to/kong-identity-dcr/
  - text: About OIDC Dynamic Client Registration
    url: https://openid.net/specs/openid-connect-registration-1_0.html
  - text: About Dev Portal OIDC authentication
    url: /dev-portal/auth-strategies/#dev-portal-oidc-authentication
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
  - text: Link static clients with self-managed OIDC
    url: /dev-portal/auth-strategies/#link-static-clients-with-self-managed-oidc
faqs:
  - q: What should I do if my IdP is not natively supported for the DCR flow?
    a: "{{site.konnect_short_name}} supports a custom HTTP DCR bridge that you can use with any third-party IdP that isn't natively supported."
  - q: What connections and protocols are involved between Dev Portal and our organization when DCR is enabled?
    a: "{{site.konnect_short_name}} will make HTTP requests to the IdP for DCR. The details of the request are IdP-specific."
  - q: What connections and protocols are involved when a custom HTTP DCR bridge is configured for a custom IdP?
    a: Kong uses HTTPS to transmit events to the domain you've provided and includes a key that can be used on your custom handler implementation to verify the events are from {{site.konnect_short_name}}.
---
Dynamic Client Registration (DCR) in {{site.konnect_short_name}} Dev Portal allows an application in the Dev Portal to register as a client with an Identity Provider (IdP). This outsources the issuer and management of application credentials to a third party, as the IdP returns a client identifier and the registered client metadata. This enables OpenID Connect (OIDC) features that the IdP supports. Dev Portal DCR adheres to [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

In Dev Portal, you can create and use multiple DCR configurations. You can configure DCR by doing the following:

{% navtabs "configure-dcr" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click [**Dev Portal**](https://cloud.konghq.com/portals/).
1. In the Dev Portal sidebar, click [**Application Auth**](https://cloud.konghq.com/portals/application-auth).
1. Click the **DCR provider** tab.
1. Click **New provider**.
1. In the **Name** field, enter the name for your DCR provider.
1. In the **Provider Type** dropdown menu, select your DCR provider.
1. In the **Auth Server** field, select your auth server.
1. Click **Create**.
1. Click the **Authentication strategy** tab.
1. Click **New authentication strategy**.
1. In the **Name** field, enter a name for your auth strategy.
1. In the **Display name** field, enter a name for your auth strategy.
1. In the **Authentication Type** dropdown menu, select "DCR".
1. In the **DCR Provider** dropdown menu, select your DCR provider.
1. In the **Scopes** field, enter your scopes.
1. In the **Credential Claims** field, enter your claims.
1. In the **Auth Methods** dropdown menu, select your auth methods. 
1. Click **Create**.
{% endnavtab %}
{% navtab "API" %}
1. Configure your DCR provider by sending a POST request to the [`/dcr-providers` endpoint](/api/konnect/application-auth-strategies/#/operations/create-dcr-provider):
{% capture provider %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/dcr-providers
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Okta"
  provider_type: "okta"
  issuer: "$ISSUER_URL"
  dcr_config:
    dcr_token: "$DCR_TOKEN"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ provider | indent: 3 }}
   
   {:.info}
   > **Note:** The `DCR_TOKEN` is the token from your IdP.

1. Export your DCR provider ID:
   ```sh
   export DCR_PROVIDER='YOUR-DCR-PROVIDER-ID'
   ```
1. Create an authentication strategy for your DCR provider by sending a POST request to the [`/application-auth-strategies` endpoint](/api/konnect/application-auth-strategies/#/operations/create-app-auth-strategy):
{% capture strategy %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/application-auth-strategies
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Okta"
  display_name: "Okta"
  strategy_type: "openid_connect"
  configs:
    openid-connect:
        issuer: "$ISSUER_URL"
        credential_claim:
        - client_id
        scopes:
        - my-scope
        auth_methods:
        - client_credentials
        - bearer
  dcr_provider_id: "$DCR_PROVIDER"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ strategy | indent: 3 }}
{% endnavtab %}
{% endnavtabs %}

## How does DCR work in Dev Portal?

After you publish an API that's linked to a Gateway Service with a DCR application authentication strategy applied, developers can register an application with your API in Dev Portal. Dev Portal registers that application as a client in the IdP through DCR and displays the returned credentials to the developer. Requests to your API succeed only when the client presents valid credentials and the application holds a registration for the linked Service.

The following diagram shows how this DCR flow works:


{% mermaid %}
sequenceDiagram
    actor Developer
    Developer->> +Dev Portal: Creates an application
    Dev Portal->>+IdP: Creates an application
    IdP->>-Dev Portal: Returns client metadata, Client ID, and secrets
    Dev Portal->>Dev Portal: Saves application record in database with ONLY Client ID mapping
    Dev Portal->>-Developer: Returns application creation success with client ID and secret
{% endmermaid %}


## Authentication methods

DCR support in {{site.konnect_short_name}} provides multiple methods by which applications can be authenticated using industry-standard protocols. These methods include:

* **Client credentials grant**: Authenticate with the client ID and secret provided to the application.
* **Bearer tokens**: Authenticate using a token requested from the IdP's `/token` endpoint.
* **Session cookie**: Allow sessions from either client credentials or bearer tokens to persist via cookie until an expiration.

Each method is available when using the following DCR identity providers:
* [Okta](/how-to/okta-dcr/)
* [Curity](/how-to/curity-dcr/)
* [Azure](/how-to/azure-ad-dcr/)
* [Auth0](/how-to/auth0-dcr/)
* [Kong Identity](/how-to/kong-identity-dcr/)

{:.info}
> **Note:** When using DCR, each application automatically receives a client ID and secret. These credentials can be used to authenticate directly with services using the client credentials grant, or to obtain an access token from the identity provider when using the bearer token authentication method.

### Authentication with bearer tokens

You can obtain a bearer access token by requesting it from the IdP's `/token` endpoint:

The following table describes the token endpoints for IdPs:

<!--vale off-->
{% table %}
columns:
  - title: Vendor
    key: vendor
  - title: Endpoint
    key: endpoint
  - title: Body
    key: body
rows:
  - vendor: "Auth0"
    endpoint: "POST `https://$REGION.auth0.com/oauth/token`"
    body: '`{ "grant_type": "client_credentials", "audience": "$YOUR_AUDIENCE" }`'
  - vendor: "Curity"
    endpoint: "POST `https://$YOUR_CURITY_DOMAIN/oauth/v2/oauth-token`"
    body: '`{ "grant_type": "client_credentials" }`'
  - vendor: "Okta"
    endpoint: "POST `https://$OKTA_SUBDOMAIN.okta.com/oauth2/default/v1/token`"
    body: '`{ "grant_type": "client_credentials" }`'
  - vendor: "Azure"
    endpoint: "POST `https://login.microsoftonline.com/$YOUR_TENANT_ID/oauth2/v2.0/token`"
    body: '`{ "grant_type": "client_credentials", "scope": "https://graph.microsoft.com/.default" }`'
  - vendor: "Kong Identity"
    endpoint: "POST `https://$YOUR_KONNECT_DOMAIN.us.identity.konghq.com/oauth2/v1/`"
    body: '`{ "grant_type": "client_credentials", "scope": "openid" }`'
{% endtable %}
<!--vale on-->


### Authentication with session cookie

After successfully authenticating using either client credentials or a bearer access token, you can use session cookie authentication to authenticate subsequent requests without including the original credentials. To use this method, ensure that your identity provider is configured to send session cookie response headers.

## Configure a custom IdP for Dynamic Client Registration

If your third-party IdP isn't natively supported, you can still use your IdP with {{site.konnect_short_name}} by using a custom HTTP DCR bridge. This HTTP DCR bridge acts as a proxy and translation layer between your IdP and DCR applications in the Dev Portal. When a developer creates a DCR application in the Dev Portal, {{site.konnect_short_name}} calls your HTTP DCR bridge which can translate the application data into a suitable format for your third-party IdP, and add additional functionality such as making API calls to other systems as part of the DCR flow.

{% mermaid %}
sequenceDiagram
    actor Developer
    participant Konnect Dev Portal
    participant HTTP DCR Bridge
    participant IdP
    Developer->>Konnect Dev Portal: Create application
    Konnect Dev Portal->>HTTP DCR Bridge: POST Create application
    HTTP DCR Bridge->>IdP: POST Create application
    IdP--)HTTP DCR Bridge: 200 OK and credentials
    HTTP DCR Bridge->>Konnect Dev Portal: Create application response (with credentials from IdP)
    Konnect Dev Portal->>Developer: Show credentials
{% endmermaid %}

> _**Figure 1:** This diagram illustrates how an HTTP DCR bridge creates an application in an IdP when a developer submits an application in the {{site.konnect_short_name}} Dev Portal. First, the developer creates an application in the Dev Portal, which triggers the portal to send the application details to the HTTP DCR bridge. The bridge then sends a `POST create application` request to the IdP. If the IdP successfully processes the request, it returns a `200` status code along with the credentials for the developer’s application. These credentials are then displayed to the developer in the Dev Portal._

### Configure custom DCR using the {{site.konnect_short_name}} Dev Portal DCR Handler

To use an unsupported IdP with DCR, you must implement an API that conforms to the [{{site.konnect_short_name}} Dev Portal DCR Handler spec](https://github.com/Kong/konnect-portal-dcr-handler/blob/main/openapi/openapi.yaml). Kong provides an example reference implementation in the [{{site.konnect_short_name}} Dev Portal DCR Handler repository](https://github.com/Kong/konnect-portal-dcr-handler). This is an example HTTP DCR bridge implementation and is not meant to be deployed in production. We encourage you to use this implementation as a guide to create your own implementation.

Any request that does not return a `2xx` status code is considered a failure and will halt the application creation process in your {{site.konnect_short_name}} Dev Portal.
