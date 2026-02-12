---
title: Enable key authentication for Dev Portal apps
permalink: /how-to/enable-key-auth-for-dev-portal/
description: Learn how to allow Dev Portal developers to authenticate with apps using key auth.
content_type: how_to

products:
    - gateway
    - dev-portal

works_on:
    - konnect
entities: []

automated_tests: false

tools:
    - deck
    # - konnect-api

tags:
    - application-registration
    - key-auth
    - authentication
search_aliases:
    - key-auth

tldr:
    q: How do I allow Dev Portal developers to authenticate with apps using key authentication?
    a: |
      In {{site.konnect_short_name}}, configure a key auth strategy with the authentication headers you want to allow and apply it to an API. Any developers who register an application for an API with this authentication strategy applied to it can authenticate by sending `apikey: $CREDENTIAL` as a header.

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline:
    - title: "{{site.konnect_product_name}} roles"
      include_content: prereqs/dev-portal-auth-strategy-roles
      icon_url: /assets/icons/gateway.svg
    - title: Configure a Dev Portal
      include_content: prereqs/dev-portal-configure
      icon_url: /assets/icons/dev-portal.svg
    - title: Register a Dev Portal developer account
      content: |
        Register a test developer account with your Dev Portal by navigating to your Dev Portal and clicking **Sign up**:
        ```sh
        open https://$PORTAL_URL/
        ```
        
        For the purpose of this tutorial, we've set our Dev Portal to automatically approve developer registrations. 
      icon_url: /assets/icons/dev-portal.svg
    - title: Publish an API
      include_content: prereqs/publish-api
      icon_url: /assets/icons/dev-portal.svg
related_resources:
  - text: Application registration
    url: /dev-portal/application-registration/
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Dev Portal developer sign-up
    url: /dev-portal/developer-signup/
  - text: Enable self-managed OIDC auth with Okta in Dev Portal
    url: /how-to/enable-oidc-auth-for-dev-portal/
cleanup:
  inline:
    - title: Clean up {{site.konnect_short_name}} environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg


faqs:
  - q: My published API is private in Dev Portal, how do I allow developers to see it?
    a: If an API is published as private, you must enable Dev Portal RBAC and [developers must sign in](/dev-portal/developer-signup/) to see APIs.
  - q: Can I configure an expiration policy for a key auth key?
    a: |
        Yes. To configure expiration for a key, do the following:
        1. In the {{site.konnect_short_name}} sidebar, click **Dev Portal**.
        1. In the Dev Portal sidebar, click **Application Auth**.
        1. Click **New authentication strategy**.
        1. In the **Name** field, enter a name for internal use.
        1. In the **Display name** field, enter a name for external use that is visible to developers.
        1. From the **Authentication Type**, select "Key-Auth".
        1. Click **Advanced configuration**.
        1. In the **Key Names** field, enter a name for your key that will display in the API request header.
        1. Enable **Key expiration policy**.
        1. In the **Key expires after** dropdown menu, select the number of days, weeks, or years after which the key will expire.
        1. Click **Save**.

        {% include /konnect/key-expiration-note.md %}

next_steps:
  - text: Learn how to manage application registration requests
    url: /dev-portal/access-and-approval/
---

## Configure key auth application authentication in Dev Portal

[Configure key auth application authentication](/api/konnect/application-auth-strategies/v2/#/operations/create-app-auth-strategy) using the `/v2/application-auth-strategies` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/application-auth-strategies
status_code: 201
method: POST
body:
    name: Key Auth
    display_name: Key Auth
    strategy_type: key_auth
    configs:
      key-auth:
        key_names:
        - apikey
        - x-api-key
        - api-key
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of the key auth strategy:

```sh
export AUTH_STRATEGY_ID='YOUR-AUTH-STRATEGY-ID'
```

## Apply the key auth strategy to an API

Now that the application auth strategy is configured, you can [apply it to an API](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal) using the `/v3/apis/{apiId}/publications/{portalId}` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
body:
    auth_strategy_ids: 
    - $AUTH_STRATEGY_ID
{% endkonnect_api_request %}
<!--vale on-->

This request will also publish the API to the specified Dev Portal.

## Create an app in Dev Portal

To use key auth credentials to authenticate with an app, you must first create an app in Dev Portal with the [test developer account you created previously](/how-to/enable-key-auth-for-dev-portal/#create-a-dev-portal-developer-account).

1. Navigate to your Dev Portal and log in with the test developer account:
   ```sh
   open https://$PORTAL_URL
   ```
   You should see `MyAPI` in the list of APIs.
1. To register an app with the API, click **View APIs**.
1. Click **Use this API**.
1. In the pop-up dialog, enter a name for the app and your client ID for your application.
1. Click **Save**.
1. Copy, save, and export your key auth credential:
   ```sh
   export CREDENTIALS='YOUR-KEY-AUTH-CREDENTIALS'
   ```
1. Click **Copy and close**.

## Validate the password grant

Now, validate the setup by accessing the `example-route` Route and passing the key auth credentials in the `apikey: $CREDENTIALS` format. You can use any of the headers that you specified when you configured the key auth strategy. 

Validate that key authentication was successfully enabled by sending a request to the `example-route` Route with your key auth credentials:

{% validation request-check %}
url: /anything
method: GET
status_code: 200
headers:
  - "apikey: $CREDENTIALS"
display_headers: true
{% endvalidation %}




