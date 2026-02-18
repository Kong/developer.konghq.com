---
title: Configure OpenID Connect with the authorization code flow and Okta
permalink: /how-to/configure-oidc-with-auth-code-flow-and-okta/
content_type: how_to
description: Learn how to configure OpenID Connect with the authorization code flow in Okta.

related_resources:
  - text: Configure OpenID Connect with the authorization code flow
    url: /how-to/configure-oidc-with-auth-code-flow/
  - text: OpenID Connect in {{site.base_gateway}}
    url: /gateway/openid-connect/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: OpenID Connect authentication flows and grants
    url: /plugins/openid-connect/#authentications
  - text: Authorization code workflow
    url: /plugins/openid-connect/#authorization-code-flow
  - text: OpenID Connect tutorials
    url: /how-to/?query=openid-connect

plugins:
  - openid-connect

entities:
  - route
  - service
  - plugin

products:
  - gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.4'

tools:
  - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: Okta
      content: |
        You need an admin account for [Okta](https://login.okta.com/). You also need an [Okta user](https://help.okta.com/en-us/content/topics/users-groups-profiles/usgp-add-users.htm) that you can use to test the OIDC auth code flow. 
      icon_url: /assets/icons/okta.svg
    - title: Ngrok
      content: |
        In this tutorial, we use [ngrok](https://ngrok.com/) to expose a local URL to the internet for local testing and development purposes. This isn't a requirement for the plugin itself.

        1. [Install ngrok](https://ngrok.com/docs/getting-started/#step-1-install).
        1. [Sign up for an ngrok account](https://dashboard.ngrok.com/) and find your [ngrok authtoken](https://dashboard.ngrok.com/get-started/your-authtoken). 
        1. Install the authtoken and connect the ngrok agent to your account:
           ```sh
           ngrok config add-authtoken $TOKEN
           ```
        1. Run ngrok:
           ```sh
           ngrok http localhost:8000
           ```
        1. In a new terminal window, export your forwarding URL as a decK environment variable appended with the `/anything` path you'll use to log in:
        {% env_variables %}
        DECK_NGROK_HOST: YOUR-FORWARDING-URL/anything
        indent: 3
        section: prereqs
        {% endenv_variables %}
      icon_url: /assets/icons/ngrok.png

tags:
  - authentication
  - openid-connect
  - okta
search_aliases:
  - oidc
  - openid connect

tldr:
  q: How do I use an authorization code to open a session with Okta, letting users log in through a browser?
  a: |
    Using the OpenID Connect plugin, set up the [auth code flow](/plugins/openid-connect/#authorization-code-flow) to connect to an identity provider (IdP) through a browser. You must specify your Okta app client ID, client secret, and issuer URL (for example: `https://domain.okta.com/oauth2/a36f045h4597`) in the OIDC plugin configuration. In addition, you must configure any `scopes` from Okta as well as your redirect URI in the plugin configuration.

faqs:
  - q: How do I enable the Proof Key for Code Exchange (PKCE) extension to the authorization code flow in the OIDC plugin?
    a: |
      The OIDC plugin supports PKCE out of the box, so you don't need to configure anything. 
      When [`config.auth_methods`](/plugins/openid-connect/reference/#schema--config-auth-methods) is set to `authorization_code`, the plugin sends the required `code_challenge` parameter automatically with the authorization code flow request. 
      
      If the IdP connected to the plugin enforces PKCE, it will be used during the authorization code flow. 
      If the IdP doesn't support or enforce PCKE, it won't be used.
  - q: How do I use custom scopes with the OIDC authorization code flow in Okta?
    a: |
      In Okta, make sure you add the custom claim to your authorization server scopes, claims, access policy, and access policy rules. Then, add your custom scope to `config.scope_claim` and to `config.scopes` in the OIDC plugin configuration.  
  - q: How do I fix the `"Cannot request 'openid' scopes` error when I try to set up OIDC auth with Okta?
    a: |
      You can't use the `openid` scope when using the `client_credentials` grant type with Okta.
      The way to fix this is to create a custom scope inside Okta and update the OpenID Connect plugin to reflect this change by adding it to `scope_claim` and `scopes`. 
 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Create an application in Okta

1. In Okta, navigate to **Applications > Applications** in the sidebar.
1. Click **Create App Integration**.
1. Select **OIDC - OpenID Connect**.
1. Select **Web Application**.
1. Click **Authorization Code** for the grant type.
1. In both the **Sign-in redirect URIs** and **Sign-out redirect URIs** fields, enter a location handled by your Route in {{site.base_gateway}}. In this tutorial, it will be your Ngrok host followed by `/anything`. For example: `https://a36f045h4597.ngrok-free.app/anything`
1. In the Assignments section, for **Controlled access**, select **Skip group assignment for now**. We will assign the app to the [test Okta user](#okta) you created in the prerequisites next.
   Save your configuration.
   {:.warning }
   > Do not select **Allow everyone in your organization to access** otherwise the access token won't be verified against Okta.
1. Export the client ID and client secret of your Okta app:

{% capture okta_vars %}
{% env_variables %}
DECK_OKTA_CLIENT_ID: 'YOUR-OKTA-APP-CLIENT-ID'
DECK_OKTA_CLIENT_SECRET: 'YOUR-OKTA-APP-CLIENT-SECRET'
{% endenv_variables %}
{% endcapture %}
{{ okta_vars | indent: 3}}

1. In the Assignment tab, assign your app to your Okta test user.

## Create an authorization server and access policy

1. Using your Okta credentials, log in to the Okta portal and click **Security > API** in the sidebar.
1. Create a server named **Kong API Management** with an audience and description.
1. Copy the issuer URL for your authorization server, strip the `/.well-known/oauth-authorization-server`, and export it as an environment variable:

   ```sh
   export DECK_ISSUER_URL='YOUR-ISSUER-URL'
   ```

   It should be formatted like `https://domain.okta.com/oauth2/a36f045h4597`. 

1. On the Access Policy tab, create a new access policy and assign the Okta application you just created.

1. Add a new rule and configure the following settings:
   * **Grant type:** Authorization Code
   * **User is:** Any user assigned the app
   * **Scopes requested:** Any scopes


## Enable the OpenID Connect plugin with the auth code flow

Set up an instance of the [OpenID Connect plugin](/plugins/openid-connect/) with the auth code flow and session authentication for Okta.

Enable the OpenID Connect plugin on the `example-service` Service:

{% entity_examples %}
entities:
  plugins:
    - name: openid-connect
      service: example-service
      config:
        issuer: ${issuer}
        client_id:
        - ${client-id}
        client_secret:
        - ${client-secret}
        redirect_uri:
        - ${redirect-uri}
        scopes:
        - openid
        - email
        - profile
        auth_methods:
        - authorization_code
        token_endpoint_auth_method: client_secret_basic
        response_mode: form_post
variables:
  issuer:
    value: $ISSUER_URL
  client-id:
    value: $OKTA_CLIENT_ID
  client-secret:
    value: $OKTA_CLIENT_SECRET
  redirect-uri:
    value: $NGROK_HOST
{% endentity_examples %}

In this example:
* `issuer`, `client ID`, `client secret`, and `client auth`: Settings that connect the plugin to your IdP (in this case, Okta).
* `auth_methods`: Specifies that the plugin should use the authorization code flow.
* `response_mode`: Set to `form_post` so that authorization codes don’t get logged to access logs.

## Validate authorization code login

Access the Route you configured in the [prerequisites](#prerequisites).
In a new browser tab, navigate to the following:

```sh
open $DECK_NGROK_HOST
```

The browser should be redirected to the Okta login page. You should be able to successfully log in with your Okta user account.
