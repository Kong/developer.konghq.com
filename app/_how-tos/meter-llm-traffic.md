---
title: Meter LLM traffic in {{site.konnect_short_name}}
description: Learn how to Meter LLM traffic using {{site.konnect_short_name}} Metering & Billing.
content_type: how_to

permalink: /metering-and-billing/meter-llm-traffic/
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

    - title: Configure AI Proxy
      include_content: prereqs/ai-gateway
      icon_url: /assets/icons/ai.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
tldr: 
  q: How can I meter LLM traffic in {{site.konnect_short_name}}, and what does the Metering & Billing system provide?
  a: |
    To meter LLM traffic in {{site.konnect_short_name}}, you can use the Metering & Billing system to track and invoice usage based on defined products, plans, and features. This guide walks you through setting up a Consumer, creating a meter for LLM tokens, defining a feature, creating a Plan with Rate Cards, and starting a subscription for billing.


automated_tests: false
---

This getting-started guide shows how to meter LLM traffic—such as token consumption or model-specific usage—from {{site.base_gateway}} and convert that raw LLM activity into billable usage with Metering & Billing in {{site.konnect_short_name}}.


## Create a Consumer

Before you configure metering and billing, you can set up a Consumer, Kong Air. [Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. Later in this guide, you'll be mapping this Consumer to a customer in Metering & Billing and assigning them to a Premium plan. Doing this allows you map existing Consumers that are already consuming your APIs to customers to make them billable.

You're going to use key [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs an API key to access any {{site.base_gateway}} Services.

<!--vale off-->
{% entity_examples %}
entities:
  consumers:
    - username: kong-air2
{% endentity_examples %}
<!--vale on-->

## Create a meter

In Metering & Billing, meters track and record the consumption of a resource or service over time.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. Enable **AI Gateway Tokens**.

You will see `kong_konnect_llm_tokens` available from the list of available meters.

## Create a feature

Meters collect raw usage data, but features make that data billable. Without a feature, usage is tracked but not invoiced. Now that you're metering LLM token usage you need to label that as something you want to price or govern. 


In this guide, you'll create a feature for the `example-service` you created in the prerequisites.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Product Catalog**.
1. Click **Create Feature**.
1. In the **Name** field, enter `ai-token`.
1. From the **Meter** dropdown menu, select "AI Gateway Tokens". 
1. Click **Add group by filter**. 
   The group by filter ensures you only bill for LLM tokens from a specific provider.
1. From the **Group by** dropdown menu, select "Provider".
1. From the **Operator** dropdown menu, select "Equals".
1. From the **Value** dropdown menu, type "OpenAI".
1. Click **Save**. 

## Create a Plan and Rate Card

Plans are the core building blocks of your product catalog. They are a collection of rate cards that define the price and access of a feature. 

A rate card describes price and usage limits or access control for a feature or item. Rate cards are made up of the associated feature, price, and optional usage limits or access control for the feature, called entitlements.

In this section, you'll create a Premium plan that charges customers based on the AI token usage at a rate of $0.00002 per use.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Product Catalog**.
1. Click the **Plans** tab.
1. Click **Create Plan**.
1. In the **Name** field, enter `Token`.
1. In the **Billing cadence** dropdown menu, select "1 month".
1. Click **Save**.
1. Click **Add Rate Card**.
1. From the **Feature** dropdown menu, select "ai-token".
1. Click **Next**.
1. From the **Pricing model** dropdown menu, select "Usage Based".
1. In the **Price per unit** field, enter `0.00002`.
1. Click **Next**. 
1. Select **Boolean**.
1. Click **Save Rate Card**.
1. Click **Publish Plan**.

## Start a subscription

Customers are the entities who pay for the consumption. In many cases, it's equal to your Consumer. Here you are going to create a customer and map our Consumer to it.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter `Kong Air`.
1. In the **Include usage from** dropdown, select "kong-air". 
1. Click **Save**.
1. Click the **Subscriptions** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select "ai-plan".
1. Click **Next**.
1. Click **Create Subscription**.


## Validate

You can run the following command to test the that the Kong Air Consumer is invoiced correctly:

<!--vale off-->
{% validation request-check %}
url: /chat
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $OPENAI_KEY'
body:
  model: gpt-4
  messages:
  - role: "user"
    content: "Say this is a test!"
{% endvalidation %}
<!--vale on-->

This will generate AI LLM token useage that will be captured by Metering & Billing.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Billing**.
1. Click the **Invoices** tab.
1. Click **Kong Air**.
1. Click the **Invoicing** tab.
1. Click **Preview Invoice**.

You'll see in Lines that `ai-token` is listed and was used six times. In this guide, you're using the sandbox for invoices. To deploy your subscription in production, configure a payments integration in **Metering & Billing** > **Settings**.