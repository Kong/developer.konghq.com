---
title: Create a cloud-hosted mock server in Insomnia

content_type: how_to

products:
- insomnia

description: Create a cloud-hosted mock server in your Insomnia project by choosing the Cloud Mock option.
tags:
- mock-servers
breadcrumbs:
  - /insomnia/
related_resources:
  - text: Authentication and authorization in Insomnia
    url: /insomnia/authentication-authorization/
  - text: Configure Okta SAML SSO in Insomnia
    url: /how-to/okta-saml-sso-insomnia/
tldr:
  q: How do I create a cloud-hosted mock server in Insomnia?
  a: In your Insomnia project, click **Create** > **Mock Server**, then enter a name, select **Cloud Mock** and click **Create**. Once the server is created, click **New Mock Route** and configure the route.
---

## Create the mock server

In your Insomnia project, click **Create** > **Mock Server**. In the dialog box, enter a name for the server, select **Cloud Mock**, and click **Create**.

The mock server opens and you can start adding routes.

## Create a route

{% include how-tos/steps/mock-route.md %}

## Validate

{% include how-tos/steps/mock-validate.md %}