---
title: Dev Portal developer sign-up
content_type: reference
layout: reference

products:
    - dev-portal
tags:
  - authentication
works_on:
    - konnect
breadcrumbs:
  - /dev-portal/

search_aliases:
  - Portal

api_specs:
  - konnect/dev-portal

description: 'Learn how developers can get started with the Dev Portal by registering and creating an application.'

related_resources:
  - text: Developer self-service and app registration
    url: /dev-portal/self-service/
  - text: Authentication strategies
    url: /dev-portal/authentication-strategies/
  - text: Dev Portal developer RBAC
    url: /dev-portal/developer-rbac/

faqs:
  - q: |
      I've logged into the Dev Portal and want to use the Dev Portal API to manage my assets, but it asks for a `portalaccesstoken`. 
      What is this token and where can I find it?
    a: |
      {% include_cached /dev-portal/portal-access-token.md %}
---

The Dev Portal enables you to quickly get access to your APIs of interest, in a self-serve way. 
Whether you're accessing the Dev Portal of a company you work for, or one that you're interested in, all you need is an application and a set of credentials to start accessing those APIs in minutes.

To create credentials, you must first create an application in which store those credentials.

The following diagram shows how to register your app in Dev Portal:

{% mermaid %}
flowchart TD
    A[Sign up for Dev Portal] --> B(Create an application)
    B --> C(Add APIs to the application)
    C --> D(Create application credentials)
    D --> |Generate in Dev Portal| E[Use application] 
    D --> |Create in IdP| E
{% endmermaid %}

## Register and create an application

All developers must register through the {{site.konnect_short_name}} Dev Portal. A {{site.konnect_short_name}} admin will provide the registration URL.

### 1. Register or sign in

Go to the Dev Portal and choose one of the following options:

* Register for access by creating an account
* Sign in using single sign-on (SSO), if enabled

Once approved, you can create an application.

### 2. Create an application

You can register an application for one or multiple APIs.

{% navtabs "register-app" %}
{% navtab "Single API" %}

1. Click **Catalog**.
1. Select the API and click **Register**.
1. Choose **Create an application**.

{% endnavtab %}
{% navtab "Multiple APIs" %}

1. Click **My Apps**.
1. Click **New App** and enter your app details.
1. Go to **Catalog**, select an API, and click **Register**.
1. Choose the app you created and click **Request Access**.

{% endnavtab %}
{% endnavtabs %}

Each application supports only one authentication strategy. When combining APIs in a single app, ensure they use the same strategy.

The Reference ID must be unique. For [OIDC](/dev-portal/auth-strategies/#configure-oidc), use the client ID from your IdP as the reference ID.

To manage your app, go to the app details and select **Edit** or **Delete**.

### 3. Create credentials

Choose one of the following methods to generate credentials:

- **API key**: Navigate to **My Apps**, select your app, and click **Generate Credential** in the Authentication pane.
- **OIDC**: Manually create the app in your identity provider (IdP) and match the Dev Portal reference ID with the client ID.

Once your app has products, credentials, and approval, you can begin making requests using the configured credentials.
