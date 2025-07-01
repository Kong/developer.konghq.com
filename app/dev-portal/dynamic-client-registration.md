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
  - text: Application registration
    url: /dev-portal/application-registration/
  - text: Configure Dynamic Client Registration with Okta
    url: /how-to/okta-dcr/
  - text: Configure Dynamic Client Registration with Curity
    url: /how-to/curity-dcr/
  - text: Configure Dynamic Client Registration with Auth0
    url: /how-to/auth0-dcr/
  - text: Configure Dynamic Client Registration with Azure
    url: /how-to/azure-dcr/
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
  - q: What connections and protocols are involved between Dev Portal and our organization when DCR is enabled?
    a: "{{site.konnect_short_name}} will make HTTP requests to the IdP for DCR. The details of the request are IdP-specific."
  - q: What connections and protocols are involved when a custom HTTP DCR bridge is configured for a custom IdP?
    a: Kong uses HTTPS to transmit events to the domain you've provided and includes a key that can be used on your custom handler implementation to verify the events are from {{site.konnect_short_name}}.
---

Dynamic Client Registration (DCR) within {{site.konnect_short_name}} Dev Portal allows applications created in the portal to automatically create a linked application in a third-party Identity Provider (IdP).

This outsources the issuer and management of application credentials to a third party, allowing for additional configuration options and compatibility with various OIDC features provided by the IdP. {{site.konnect_short_name}} offers the flexibility to create multiple DCR configurations.

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
{% endtable %}
<!--vale on-->


### Authentication with session cookie

After successfully authenticating using either client credentials or a bearer access token, you can use session cookie authentication to authenticate subsequent requests without including the original credentials. To use this method, ensure that your identity provider is configured to send session cookie response headers.

## Configure a custom IdP for Dynamic Client Registration

{{site.konnect_short_name}} Dev Portal supports a variety of the most widely adopted identity provider (IdP) for Dynamic Client Registration (DCR):

* Auth0
* Azure
* Curity
* Okta

If your third-party IdP is not on this list, you can still use your IdP with {{site.konnect_short_name}} by using a custom HTTP DCR bridge. This HTTP DCR bridge acts as a proxy and translation layer between your IdP and DCR applications in the Dev Portal. When a developer creates a DCR application in the Dev Portal, {{site.konnect_short_name}} calls your HTTP DCR bridge which can translate the application data into a suitable format for your third-party IdP.

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
