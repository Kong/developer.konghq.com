---
title: Enable SAML authentication using Microsoft Entra
permalink: /how-to/enable-saml-authentication-with-microsoft-entra/
description: Use the SAML plugin to enable SAML authentication for users configured in Microsoft Entra.
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

breadcrumbs:
  - /gateway/authentication/
products:
    - gateway

plugins:
  - saml

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
    - authentication

tldr:
    q: How can I set up SAML authentication with Microsoft Entra?
    a: Create your SAML application in Microsoft Entra, then create an anonymous Consumer in {{site.base_gateway}}. Enable the SAML plugin and configure it with the SAML application identifier, login URL, and certificate.

tools:
    - deck

faqs:
  - q: Why is my valid certificate not being accepted?
    a: |
      There may be an issue with the formatting of the Certificate. Standard certificates contain a header and a footer:
      ```
      -----BEGIN CERTIFICATE-----
      <certificate contents>
      -----END CERTIFICATE-----
      ```
      When specifying a certificate in the `idp_certificate` field, these must be removed. The value should be the certificate contents only.

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Microsoft Entra SAML application
      content: |
        This tutorial uses Microsoft Entra as a SAML identity provider.

        1. Make sure you have the appropriate permissions and follow the steps in the Microsoft docs to [set up a SAML application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal).
        1. [Enable SSO](https://learn.microsoft.com/en-us/entra/identity/app-proxy/conceptual-sso-apps#update-the-saml-configuration) for the application.
        1. Assign at least one user to the application. 
        1. From the **Single sign-on** page of the application, get the values of the following fields and add them to your environment:
            * **Identifier (Entity ID)**
            * **Login URL** 
            * **Certificate (Base64)** 

            {% env_variables %}
            DECK_IDENTIFIER: SAML-application-identifier
            DECK_LOGIN_URL: SAML-login-URL
            DECK_CERTIFICATE: certificate-contents
            {% endenv_variables %}

        {:.warning}
        > Do not include the `BEGIN CERTIFICATE` and `END CERTIFICATE` lines in the certificate variable. Add only the certificate contents.

      icon_url: /assets/icons/azure.svg
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

## Create an anonymous Consumer

In this example, we want to manage users through Microsoft Entra only, so we'll use the `anonymous` Consumer:
{% entity_examples %}
entities:
    consumers:
        - username: anonymous
{% endentity_examples %}

## Enable the SAML plugin

Enable the [SAML plugin](/plugins/saml/) and provide the information to connect to your SAML application.
We also need to provide a value for [`config.session_secret`](/plugins/saml/reference/#schema--config-session-secret), which should be a random 32-character string.

{% entity_examples %}
entities:
    plugins:
        - name: saml
          config:
            anonymous: anonymous
            issuer: ${identifier}
            idp_sso_url: ${url}
            assertion_consumer_path: /consume
            validate_assertion_signature: false
            session_secret: uwcLGoTJCWnHWZdVpbLYKlztNOyoGJ07
            idp_certificate: ${certificate}

variables:
  identifier:
    value: $IDENTIFIER
  url:
    value: $LOGIN_URL
  certificate:
    value: $CERTIFICATE
{% endentity_examples %}

## Validate

To validate that the SAML configuration works, go to `$KONNECT_PROXY_URL/anything` in a browser.
{: data-deployment-topology="konnect" }

To validate that the SAML configuration works, go to `http://localhost:8000/anything` in a browser.
{: data-deployment-topology="on-prem" }

When prompted, log in with a user that has access to the SAML application.