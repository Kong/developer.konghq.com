---
title: "Integrate Stripe with {{site.metering_and_billing}}"
content_type: reference
description: "Learn how to send invoices to Stripe and calculate Stripe tax with the {{site.metering_and_billing}} Stripe integration."
layout: reference
products:
  - metering-and-billing
tools:
    - konnect-api
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
related_resources:
  - text: "{{site.konnect_short_name}} {{site.metering_and_billing}}"
    url: /metering-and-billing/
  - text: "Subjects"
    url: /metering-and-billing/subjects/
---

## Prerequisites

: Need something in Stripe already? API key 

## Install Stripe integration in {{site.metering_and_billing}}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Settings**.
1. Click **Stripe**.
1. Click **Install**.
1. In the **Stripe API Key** field, enter your Stripe API key (secret key). For example: `sk_523d...`.
1. Click **Install Stripe app**.
1. Choose how you want to send invoices:
   * To send invoices and collect payment automatically with Stripe, click **Auto Collection**.
   * To send an invoice and allow the customer the pay it in their preferred way, click **Send Invoice**.
   <!-- if you do advanced, you can customize these profiles and it looks like you can also set up tax here too, not sure if we want to do those all here or do them later, looks like you can only set the one profile for now as well.-->
1. Click **Create Billing Profile**.
1. MAYBEEE? Disable **Set this as the new default billing profile**. <!-- the thought behind this is maybe they aren't ready to cut over yet, maybe they want to set up an additonal profile, etc.-->
1. ^ If this is yes. Click **Keep Current Default Profile**.
1. Click **Start Billing**.


## Customers 
    ↳ existing customer in stripe? Provide Stipe ID. 
    ↳ no existing customer in Stripe? Do Checkout Session 
    must have payment method in Stripe 

## Invoicing (so Stripe does the invoicing) 
    ↳ self-serve? Charge automatically 
    ↳ enterprise customer? Send invioce 
    Note. can do BOTH and set up multiple billing profiles 4. Optional (?): let Stripe calculate tax