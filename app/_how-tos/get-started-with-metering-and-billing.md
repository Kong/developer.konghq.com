---
title: Get started with Metering and Billing in {{site.konnect_short_name}}
description: Learn how to...
content_type: how_to

permalink: /metering-and-billing/get-started/
breadcrumbs:
  - /metering-and-billing/

products:
    - metering-and-billing

works_on:
    - konnect

tags:
    - get-started

tldr: 
  q: What is Metering and Billing in {{site.konnect_short_name}}, and how can I get started with it?
  a: |
    blah

tools:
    - deck
  
prereqs:
  inline:
    - title: cURL
      content: |
        [cURL](https://curl.se/) is used to send requests to {{site.base_gateway}}. 
        `curl` is pre-installed on most systems.
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

## Create a Consumer

Create the two consumers, one for the free and one for premium. These will be mapped to our customers/subjects later on

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}.
We're going to use key [authentication](/gateway/authentication/) in this tutorial, so the Consumer needs an API key to access any {{site.base_gateway}} Services.

{% entity_examples %}
entities:
  consumers:
    - username: ariel
      keyauth_credentials:
        - key: ariel-key
    - username: rosario
      keyauth_credentials:
        - key: rosario-key
{% endentity_examples %}

## Enable authentication

Authentication lets you identify a Consumer so that you can apply rate limiting.
This example uses the [Key Authentication](/plugins/key-auth/) plugin, but you can use any [authentication plugin](/plugins/?category=authentication) that you prefer.

Enable the plugin globally, which means it applies to all {{site.base_gateway}} Services and Routes:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Enable rate limiting

Set rate limits for the consumers. Free consumer gets 1,000 requests for example_service and premium gets 5,000 requests for the same service/api.

Enable the [Rate Limiting plugin](/plugins/rate-limiting/) for the Consumer. 
In this example, the limit is 5 requests per minute and 1000 requests per hour.

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      consumer: ariel
      config:
        minute: 5
        hour: 1000
    - name: rate-limiting
      consumer: rosario
      config:
        minute: 5
        hour: 1000
{% endentity_examples %}

## Configure ACL plugin

Configure the ACL plugin to only allow access to the service for customers who have signed up, so our two consumers:

{% entity_examples %}
entities:
  plugins:
    - name: acl
      service: example_service
      config:
        allow:
        - free
        - premium
{% endentity_examples %}

## Create a system access token in Konnect
to ingest usage events?

## Create a meter

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. Enable **API Gateway Requests**.

This will pull in request proxied by your API Gateway in {{site.konnect_short_name}} to Metering & Billing.

## Create a feature

Creating a feature that is linked to our service:

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Product Catalog**.
1. Click **Create Feature**>
1. In the **Name** field, enter `example_service`.
1. From the **Meter** dropdown menu, select "kong_konnect_api_request". 
1. Click **Add group by filter**.
1. From the **Group by** dropdown menu, select "service_name".
1. From the **Operator** dropdown menu, select "Equals".
1. From the **Value** dropdown menu, select "example_service".
1. Click **Save**. 


## Create a plan

Creating plans for our feature.

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Product Catalog**.
1. Click the **Plans** tab.
1. Click **Create Plan**.
1. In the **Name** field, enter `Free`.
1. In the **Billing cadence** dropdown menu, select "1 month".
1. Click **Save**.
1. Click **Add Rate Card**.
1. From the **Feature** dropdown menu, select "example_service".
1. Click **Next**.
1. From the **Pricing model** dropdown menu, select "Free".
1. Click **Next**.
1. From the **Entitlements** dropdown, select "Metered".
1. From the **Usage Period Interval** dropdown, select "Monthly".
1. In the **Allowance for Period** field, enter `1000`. 
1. Click **Save Rate Card**.
1. Click **Publish Plan**.
1. Navigate back to **Plans** in the breadcrumbs.
1. Click **Create Plan**.
1. In the **Name** field, enter `Premium`.
1. In the **Billing cadence** dropdown menu, select "1 month".
1. Click **Save**.
1. From the **Feature** dropdown menu, select "example_service".
1. Click **Next**.
1. From the **Pricing model** dropdown menu, select "Package".
1. In the **Price per package** field, enter `1`.
1. In the **Quantity per package** field, enter `5000`.
1. Click **Next**.
1. From the **Entitlements** dropdown, select "Metered".
1. In the **Allowance for Period** field, enter `5000`. 
1. Click **Save Rate Card**.
1. Click **Publish Plan**.

## Map Consumers to customers

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter `Ariel`.
1. In the **Include usage from** dropdown, select "Ariel". 
1. Click **Save**.
1. Click the **Subscriptions** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select "Free".
1. Click **Next**.
1. Click **Create Subscription**.
1. Navigate back to **Customers** in the breadcrumbs. 
1. Click **Create Customer**.
1. In the **Name** field, enter `Rosario`.
1. In the **Include usage from** dropdown, select "Rosario". 
1. Click **Save**.
1. Click the **Subscriptions** tab.
1. Click **Create a Subscription**.
1. From the **Subscribed Plan** dropdown, select "Premium".
1. Click **Next**.
1. Click **Create Subscription**.

Note: Want to delete a customer? Cancel their subscription first and then you can delete them.

## Validate??

Customer uses the service and we see the invoice triggered?

You can run the following command to test the rate limiting as the Consumer:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
headers:
  - 'apikey:ariel-key'
{% endvalidation %}

Now, check the invoice that was created in Metering & Billing:

1. In the {{site.konnect_short_name}} sidebar, click **Metering & Billing**.
1. In the Metering & Billing sidebar, click **Billing**.
1. Click the **Invoices** tab.
1. See the invoice created?