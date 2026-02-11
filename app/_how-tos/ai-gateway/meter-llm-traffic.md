---
title: Monetize LLM traffic in {{site.konnect_short_name}}
permalink: /how-to/meter-llm-traffic/
description: Learn how to Meter LLM traffic using {{site.konnect_short_name}} {{site.metering_and_billing}}.
content_type: how_to

breadcrumbs:
  - /metering-and-billing/

products:
    - gateway
    - metering-and-billing

works_on:
    - konnect

tags:
    - get-started

tools:
    - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/ai.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
tldr:
  q: How can I meter LLM traffic in {{site.konnect_short_name}}, and what does the {{site.metering_and_billing}} provide?
  a: |
    To meter LLM traffic in {{site.konnect_short_name}}, you can use the {{site.metering_and_billing}} to track and invoice usage based on defined products, plans, and features. This guide walks you through setting up a Consumer, creating a meter for LLM tokens, defining a feature, creating a Plan with Rate Cards, and starting a subscription for billing.
related_resources:
  - text: "{{site.ai_gateway_name}}"
    url: /ai-gateway/
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/
  - text: Metering reference
    url: /metering-and-billing/metering/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/
  - text: Billing, invoicing, and subscriptions
    url: /metering-and-billing/billing-invoicing-subscriptions/
  - text: Meter and bill {{site.base_gateway}} API requests
    url: /metering-and-billing/get-started/

automated_tests: false
---

This getting-started guide shows how to meter LLM traffic—such as token consumption or model-specific usage—from {{site.base_gateway}} and convert that raw LLM activity into billable usage with {{site.metering_and_billing}} in {{site.konnect_short_name}}.


## Create a Consumer

Before you configure {{site.metering_and_billing}}, you can set up a Consumer, Kong Air. [Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. Later in this guide, you'll be mapping this Consumer to a customer in {{site.metering_and_billing}} and assigning them to a Premium plan. Doing this allows you map existing Consumers that are already consuming your APIs to customers to make them billable.

{% entity_examples %}
entities:
  consumers:
    - username: kong-air
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}

To connect LLM usage to the Consumer, you'll need to configure an [authentication plugin](/plugins/?category=authentication). In this tutorial, we'll use [Key Authentication](/plugins/key-auth/). This will require the Consumer to use an API key to access any {{site.base_gateway}} Services.

Configure the Key Auth plugin on the Service:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
{% endentity_examples %}

## Configure the AI Proxy plugin

To set up AI Proxy with OpenAI, specify the [model](https://platform.openai.com/docs/models) and set the appropriate authentication header. To collect meters, you must also enable `log_payloads` and `log_statistics`.

In this example, we'll use the gpt-4o model:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy
      config:
        route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: Bearer ${openai_api_key}
        model:
          provider: openai
          name: gpt-4o
        logging:
          log_payloads: true
          log_statistics: true
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Enable Metering

In {{site.metering_and_billing}}, meters track and record the consumption of a resource or service over time.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. For {{site.ai_gateway}} Tokens, click **Enable Related API Gateways**.
1. Select the `quickstart` control plane.
1. Click **Enable 1 Gateway**.

You will see `quickstart` in the list of available meters.

## Create a feature

Meters collect raw usage data, but features make that data billable. Without a feature, usage is tracked but not invoiced. Now that you're metering LLM token usage, you need to label that as something you want to price or govern.


In this guide, you'll create a feature for the `example-service` you created in the prerequisites.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Product Catalog**.
1. Click **Create Feature**.
1. In the **Name** field, enter `ai-token`.
1. From the **Meter** dropdown menu, select "{{site.ai_gateway}} Tokens".
1. Click **Add group by filter**.
   The group by filter ensures you only bill for LLM tokens from a specific provider.
1. From the **Group by** dropdown menu, select "Provider".
1. From the **Operator** dropdown menu, select "Equals".
1. In the **Value** dropdown menu, enter `openai`.
1. Click **Add group by filter**.
1. From the **Group by** dropdown menu, select "type".
1. From the **Operator** dropdown menu, select "Equals".
1. In the **Value** dropdown menu, enter `request`.
1. Click **Save**.

## Create a Plan and Rate Card

Plans are the core building blocks of your product catalog. They are a collection of rate cards that define the price and access of a feature.

A rate card describes price and usage limits or access control for a feature or item. Rate cards are made up of the associated feature, price, and optional usage limits or access control for the feature, called entitlements.

In this section, you'll create a Premium plan that charges customers based on the AI token usage at a rate of $0.00002 per use.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Product Catalog**.
1. Click the **Plans** tab.
1. Click **Create Plan**.
1. In the **Name** field, enter `Token`.
1. In the **Billing cadence** dropdown menu, select "1 month".
1. Click **Save**.
1. Click **Add Rate Card**.
1. From the **Feature** dropdown menu, select "ai-token".
1. Click **Next Step**.
1. From the **Pricing model** dropdown menu, select "Usage Based".
1. In the **Price per unit** field, enter `1`.

   {:.info}
   > We're using $1 here to make it easy to see the cost changes in the customer invoice. Be sure to change this price in a production instance to match your own pricing model.
1. Click **Next Step**.
1. Select **Boolean**.
1. Click **Save Rate Card**.
1. Click **Publish Plan**.
1. Click **Publish**.

## Start a subscription

Customers are the entities who pay for the consumption. In many cases, it's equal to your Consumer. Here you are going to create a customer and map our Consumer to it.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter `Kong Air`.
1. In the **Include usage from** dropdown, select "kong-air".
1. Click **Save**.
1. Click the **Subscriptions** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select "Token".
1. Click **Next Step**.
1. Click **Start Subscription**.


## Validate

You can run the following command to test the that the Kong Air Consumer is invoiced correctly:

<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'apikey: hello_world'
body:
    messages:
        - role: "system"
          content: "You are a mathematician"
        - role: "user"
          content: "What is 1+1?"
{% endvalidation %}
<!--vale on-->

This will generate AI LLM token usage that will be captured by {{site.metering_and_billing}}.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the **Invoices** tab.
1. Click **Kong Air**.
1. Click the **Invoicing** tab.
1. Click **Preview Invoice**.

You'll see in Lines that `ai-token` is listed and was used once. In this guide, you're using the sandbox for invoices. To deploy your subscription in production, configure a payments integration in **{{site.metering_and_billing}}** > **Settings**.