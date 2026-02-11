---
title: Get started with {{site.metering_and_billing}} in {{site.konnect_short_name}}
description: Learn how to meter and monetize API Gateway requests with {{site.konnect_short_name}} and {{site.metering_and_billing}}.
content_type: how_to

permalink: /metering-and-billing/get-started/
breadcrumbs:
  - /metering-and-billing/

products:
    - gateway
    - metering-and-billing

works_on:
    - konnect

tags:
    - get-started

tldr:
  q: What is {{site.metering_and_billing}} in {{site.konnect_short_name}}, and how can I get started with it?
  a: |
    [{{site.metering_and_billing}}](/metering-and-billing/) provides flexible billing and metering for AI and DevTool companies. It also includes real-time insights and usage limit enforcement.

    This tutorial will help you get started with {{site.metering_and_billing}} by setting up metering based on {{site.base_gateway}} API requests, turn raw API usage into billable product offerings by defining features and pricing plans, and start subscriptions to assign to customers.

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        You need the [{{site.metering_and_billing}} Admin role](/konnect-platform/teams-and-roles/#metering-billing) in {{site.konnect_short_name}} to configure {{site.metering_and_billing}}.
      icon_url: /assets/icons/kogo-white.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
related_resources:
  - text: "{{site.base_gateway}}"
    url: /gateway/
  - text: Product Catalog reference
    url: /metering-and-billing/product-catalog/
  - text: Metering reference
    url: /metering-and-billing/metering/
  - text: Customers and usage attribution
    url: /metering-and-billing/customer/
  - text: Billing, invoicing, and subscriptions
    url: /metering-and-billing/billing-invoicing-subscriptions/
  - text: Meter and bill {{site.ai_gateway}} LLM tokens
    url: /how-to/meter-llm-traffic/
min_version:
    gateway: '3.4'
next_steps:
  - text: See all {{site.base_gateway}} tutorials
    url: /how-to/?products=gateway
  - text: Learn about {{site.base_gateway}} entities
    url: /gateway/entities/
  - text: Learn about how {{site.base_gateway}} is configured
    url: /gateway/configuration/
  - text: See all {{site.base_gateway}} plugins
    url: /plugins/
automated_tests: false
---

This getting-started guide shows how you can meter {{site.base_gateway}} API requests and invoice your customers based on their API consumption with {{site.metering_and_billing}} in {{site.konnect_short_name}}.

In this guide, you'll:
* Create a {{site.base_gateway}} Consumer that you'll map as a customer
* Set up a meter for {{site.base_gateway}} API requests
* Create a premium plan based on API usage
* Start subscriptions for a customer
* Generate an invoice for a customer on the paid premium plan and see their API usage

The following diagram shows how {{site.base_gateway}} entities and {{site.metering_and_billing}} entities are associated:

{% mermaid %}
flowchart TB
  subgraph gateway["<b>Kong Gateway</b>"]
    direction LR
        service["example-service"]
        route["example-route"]
        consumer1["Consumer-Kong Air"]
  end
  subgraph metering["<b>Konnect {{site.metering_and_billing}}</b>"]
    direction LR
        meter["Meter"]
    subgraph plan["Premium Plan"]
      direction LR
          feature2["Feature (example-service)"]
          rate-card2["Rate card"]
    end
    subgraph subscription["Premium Subscription"]
      direction LR
          customer1["Customer (Kong Air)"]
    end
  end
    gateway --> metering
    service --> meter
    meter --> feature2
    consumer1 --> customer1
    subscription --> plan

{% endmermaid %}


## Create a Consumer

Before you configure {{site.metering_and_billing}}, you can set up a Consumer, Kong Air. [Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. Later in this guide, you'll be mapping this Consumer to a customer in {{site.metering_and_billing}} and assigning them to a Premium plan. Doing this allows you map existing Consumers that are already consuming your APIs to customers to make them billable.

You're going to use key [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs an API key to access any {{site.base_gateway}} Services.

<!--vale off-->
{% entity_examples %}
entities:
  consumers:
    - username: kong-air
      keyauth_credentials:
        - key: air-key
{% endentity_examples %}
<!--vale on-->

## Enable authentication

Authentication lets you identify a Consumer so you can invoice them as customers after they've consumed the resource, in this case, the API request.
This example uses the [Key Authentication](/plugins/key-auth/) plugin, but you can use any [authentication plugin](/plugins/?category=authentication) that you prefer.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}
<!--vale on-->

## Create a meter

In {{site.metering_and_billing}}, meters track and record the consumption of a resource or service over time. This usage can take various forms, such as API requests, compute time seconds, or tokens consumed. Usage metering is commonly event-based to ensure accuracy and data you can audit.

In this guide, you'll enable API Gateway requests for metering. This will meter API request traffic in {{site.metering_and_billing}} so that you can charge customers for API traffic usage.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the API Gateway Requests settings, click **Enable Gateways**.
1. Select the "quickstart" control plane.
1. Click **Enable 1 Gateways**.


## Create a feature

Meters collect raw usage data, but features make that data billable. Without a feature, usage is tracked but not invoiced. Now that you're metering API consumption, you need to associate traffic from the `example-service` Gateway Service with a feature as something you want to price or govern.

Features are customer-facing, and show up on the invoice for paid plans. Feature examples could include things like flight data requests, GPT-5 input tokens, or available LLM models.

In this guide, you'll create a feature for the `example-service` you created in the prerequisites.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Product Catalog**.
1. Click **Create Feature**.
1. In the **Name** field, enter `example-service`.
1. From the **Meter** dropdown menu, select "API Gateway Requests".
1. Click **Add group by filter**.
   The group by filter ensures you only bill for traffic to `example-service`, not all {{site.base_gateway}} traffic. This lets you offer different pricing for different APIs.
1. From the **Group by** dropdown menu, select "service_name".
1. From the **Operator** dropdown menu, select "Equals".
1. From the **Value** dropdown menu, select "example-service".
1. Click **Save**.

## Create a Premium plan

Plans are the core building blocks of your product catalog. They are a collection of rate cards that define the price and access of a feature. Plans can be assigned to customers by starting a subscription.

A rate card describes price and usage limits or access control for a feature or item. Rate cards are made up of the associated feature, price, and optional usage limits or access control for the feature, called entitlements.

In this section, you'll create a Premium plan that grants paying customers access to the `example-service` at a rate of 5,000 requests per month:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Product Catalog**.
1. Click the **Plans** tab.
1. Click **Create Plan**.
1. In the **Name** field, enter `Premium`.
1. In the **Billing cadence** dropdown menu, select "1 month".
1. Click **Save**.
1. Click **Add Rate Card**.
1. From the **Feature** dropdown menu, select "example-service".
1. Click **Next Step**.
1. From the **Pricing model** dropdown menu, select "Usage based".
1. In the **Price per unit** field, enter `1`.
1. Click **Next Step**.
1. Click **Save Rate Card**.
1. Click **Publish Plan**.

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
1. From the **Subscribed Plan** dropdown, select "Premium".
1. Click **Next Step**.
1. Click **Create Subscription**.

<!--Note: Want to delete a customer? Cancel their subscription first and then you can delete them.-->

## Validate

You can run the following command to test the that the Kong Air Consumer is invoiced correctly:

<!--vale off-->
```sh
for _ in {1..6}; do
  curl  -i $KONNECT_PROXY_URL/anything \
       -H "apikey:air-key"
  echo
done
```
<!--vale on-->

This will generate six requests. Now, check the invoice that was created in {{site.metering_and_billing}}:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click the **Invoices** tab.
1. Click **Kong Air**.
1. Click the **Invoicing** tab.
1. Click **Preview Invoice**.

You'll see in Lines that `example-service` is listed and was used six times. In this guide, you're using the sandbox for invoices. To deploy your subscription in production, configure a payments integration in **{{site.metering_and_billing}}** > **Settings**.