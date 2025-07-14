---
title: Configure OpenID Connect with the authorization code flow and Okta
content_type: how_to
description: Learn how to configure OpenID Connect with the authorization code flow in Okta.

related_resources:
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
      include_content: prereqs/okta-sso
      icon_url: /assets/icons/okta.svg

tags:
  - authentication
  - openid-connect
  - okta
search_aliases:
  - oidc

tldr:
  q: How do I use an authorization code to open a session with Okta, letting users log in through a browser?
  a: Using the OpenID Connect plugin, set up the [auth code flow](/plugins/openid-connect/#authorization-code-flow) to connect to an identity provider (IdP) through a browser, and use session authentication to store open sessions. You can do this by specifying `authorization_code` and `session` in the `config.auth_methods` plugin settings.

faqs:
  - q: How do I enable the Proof Key for Code Exchange (PKCE) extension to the authorization code flow in the OIDC plugin?
    a: |
      The OIDC plugin supports PKCE out of the box, so you don't need to configure anything. 
      When [`config.auth_methods`](/plugins/openid-connect/reference/#schema--config-auth-methods) is set to `authorization_code`, the plugin sends the required `code_challenge` parameter automatically with the authorization code flow request. 
      
      If the IdP connected to the plugin enforces PKCE, it will be used during the authorization code flow. 
      If the IdP doesn't support or enforce PCKE, it won't be used.
 
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

### Configure Okta

1. [Register](https://developer.okta.com/docs/guides/add-an-external-idp/openidconnect/register-app-in-okta/) the application you are using Kong to proxy.
1. From the left menu, select **Applications**, then **Create App Integration**.
1. Select the application type:

    1. Under **Sign-in method**, select **OIDC - OpenID Connect**.
    1. Under **Application Type**, select **Web Application**.

1. Select **Next**. Configure the application:
    1. Create a unique name for your application.
    1. Under **Grant Type**, select **Authorization Code**.
    1. In both the **Sign-in redirect URIs** and
    **Sign-out redirect URIs** fields, enter a location handled by your Route
    in {{site.base_gateway}}.

        For this example, you can enter `http://localhost:8000/anything`.
    1. In the Assignments section, for **Controlled access**, select **Limit access to selected groups**. This preferred access level sets the permissions for
    Okta admins. 
    {:.warning }
    > Do not select **Allow everyone in your organization to access** otherwise the **access token** won't be verified against Okta.
    1. **Directory > People** and create a person:
        Name: Alex
        Last Name: Doe
        Email: Email of choice
        Select **I will set password**.
        Password: `BlueGorilla92!`
        Deselect **User must change password on first login**.
    1. Assign app to person: **Applications > Applications**, click your app, **Assignments** tab. from the **Assign** dropdown menu, select **Assign to People**. Assign to Alex Doe.
1. Export the client ID and client secret of your Okta app:
   ```sh
   export DECK_OKTA_CLIENT_ID='YOUR-OKTA-APP-CLIENT-ID'
   export DECK_OKTA_CLIENT_SECRET='YOUR-OKTA-APP-CLIENT-SECRET'
   ```

1. Add an Authorization Server. From the left sidebar, go to **Security > API > Authorization Server** and create a server named **Kong API Management** with an audience and description. Click **Save**.
1. Export your issuer URL as an environment variable:
   ```sh
   export DECK_ISSUER_URL='YOUR-ISSUER-URL'
   ```
   It should be formatted like `https://$DOMAIN.okta.com/oauth2/$AUTH-SERVER-ID`. 
4. Click the **Scopes** tab, and click **Add Scope**.

1. Add a scope called `scp`. 

1. On the Access Policy tab, create a new access policy and assign your Okta application you just created.

1. Add a new rule and configure the following settings:
   * **Grant type:** Authorization Code
   * **Scopes requested:** `scp` 

## Enable the OpenID Connect plugin with the auth code flow

Using the Keycloak and {{site.base_gateway}} configuration from the [prerequisites](#prerequisites), 
set up an instance of the OpenID Connect plugin with the auth code flow and session authentication.

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
        - http://host.docker.internal:8000/anything
        scopes_claim:
        - scp
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
{% endentity_examples %}

In this example:
* `issuer`, `client ID`, `client secret`, and `client auth`: Settings that connect the plugin to your IdP (in this case, the sample Keycloak app).
* `auth_methods`: Specifies that the plugin should use session auth and the authorization code flow.
* `response_mode`: Set to `form_post` so that authorization codes won’t get logged to access logs.
* `preserve_query_args`: Preserves the original request query arguments through the authorization code flow redirection.
* `login_action`: Redirects the client to the original request URL after the authorization code flow. This turns the POST request into a GET request, and the browser address bar is updated with the original request query arguments.
* `login_tokens`: Configures the plugin so that tokens aren't included in the browser address bar.
* `authorization_endpoint`: Sets a custom endpoint for authorization, overriding the endpoint returned by discovery through the IdP. 
We need this setting because we're running the example through Docker, otherwise the discovery endpoint will try to access an internal Docker host.

## Validate authorization code login

Access the Route you configured in the [prerequisites](#prerequisites) with some query arguments. 
In a new browser tab, navigate to the following:

```sh
http://localhost:8000/anything?hello=world
```

The browser should be redirected to the Keycloak login page. 

Let's check what happens if you access the same URL using cURL:

{% validation request-check %}
url: /anything?hello=world
method: GET
status_code: 302
display_headers: true
{% endvalidation %}

You should see a `302` response with the session access token in the response, and a `Location` header that shows where the request is being redirected to.