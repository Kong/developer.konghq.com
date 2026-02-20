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

The Stripe app integrates OpenMeter with Stripe to provide additional features and seamlessly integrate with existing workflows. For example, the Stripe app can be configured to synchronize invoices to Stripe, calculate tax, and collect payments automatically.

The Stripe app integrates OpenMeter with the following Stripe products:
* Stripe Tax: Calculate taxes automatically via Stripe based on location, product, or other criteria.
* Stripe Invoicing: Sync and deliver invoices via Stripe and collect payments.
* Stripe Payments: Collect payments via Stripe payment gateway using multiple payment methods.

OpenMeter uses apps to extend the functionality of the platform. For example, you can use apps to integrate with external systems like Stripe.

In the case of the Stripe app, OpenMeter handles:
* Usage metering
* Products and prices
* Subscription management
* Billing


While Stripe handles:
* Credit card details
* Payment collection
* Tax calculations (if enabled)
* Sending invoices to customers
* The OpenMeter Stripe app synchronizes invoices to Stripe Invoicing for automatic tax calculations and payment collection.

{:.info}
> **Stripe fees:** Stripe will charge a fee for each invoice, tax calculations and payment according to your contract with them. Please see the Stripe Fees page for more information.

## Stripe Payments

Collect payments quickly and securely via Stripe's trusted payment gateway. Your customers can choose from various payment methods—credit card, ACH, and more—to improve the overall customer experience and speed up cash flow.

In OpenMeter you can configure the default payment method and currency to use for payments per customer and billing profile.

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
   If you want to do both, you can configure an additional billing profile after setting up Stripe.
1. If you want to configure Stripe to collect taxes, do blahhhhhh
1. Click **Create Billing Profile**.
1. Do one of the following:
   * To set this as the default billing profile, click **Start Billing**.
   * To not set this as the default billing profile, disable **Set this as the new default billing profile** and click **Keep Current Default Profile**.


## Customers 

### Existing customer in stripe

To connect an existing Stripe customer to an OpenMeter customer, you can do so in the customer details page in OpenMeter or via the API.

{:.info}
> **Default payment method:** Be sure that you also set the Stripe Default Payment Method ID in OpenMeter or to set a default payment method in Stripe for the customer. This is necessary to automatically charge the customer when an invoice is created.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter `Stripe`.
1. Click **Save**.
1. Add stripe ID via API:
```sh
curl --request PUT \
  --url https://us.api.konghq.com/v3/openmeter/customers/01G65Z755AFWAKHE12NY0CQ9FH/billing \
  --header 'Accept: application/json, application/problem+json' \
  --header 'Authorization: Bearer ' \
  --header 'Content-Type: application/json' \
  --data '{
  "billing_profile": {
    "id": "01G65Z755AFWAKHE12NY0CQ9FH"
  },
  "app_data": {
    "stripe": {
      "customer_id": "cus_1234567890",
      "default_payment_method_id": "pm_1234567890",
      "labels": {
        "env": "test"
      }
    },
    "external_invoicing": {
      "labels": {
        "env": "test"
      }
    }
  }
}'
```

stripe payment method for sandbox: https://docs.stripe.com/payments/ach-direct-debit/accept-a-payment?payment-ui=checkout#test-account-numbers

PM ID: Customers > Click customer > click action menu next to payment method > Select "Copy ID". 

### No existing customer in Stripe (checkout session)

OpenMeter provides a simple API to create a customer and generate a Stripe Checkout link to collect payment details. 

When a customer completes the checkout form and provides their payment method, OpenMeter will automatically set the Stripe Customer ID and the payment method to the default payment method for the OpenMeter customer. This is done via OpenMeter listening to the setup_intent.succeeded event via webhooks. This webhook is setup automatically when the OpenMeter Stripe App is installed.

1. Generate a Stripe Checkout URL to the payment form:
```sh
curl --request POST \
  --url https://us.api.konghq.com/v3/openmeter/customers/01G65Z755AFWAKHE12NY0CQ9FH/billing/stripe/checkout-sessions \
  --header 'Accept: application/json, application/problem+json' \
  --header 'Authorization: Bearer YOUR_KONNECT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{
    "customer": {
      "name": "ACME, Inc.",            # optional display name
      "currency": "USD",               # optional, helps Stripe setup
      "usageAttribution": {            # optional subject keys if relevant
        "subjectKeys": ["subject-123"]
      }
    },
    "options": {
      "successURL": "https://example.com/success",
      "mode": "setup"                  # e.g., "setup" to collect payment method
    }
  }'
```
  
  The session operates in “setup” mode, which collects payment details without charging
the customer immediately. The collected payment method can be used for future
subscription billing.

For hosted checkout sessions, redirect customers to the returned URL. For embedded
sessions, use the `client_secret` to initialize Stripe.js in your application.

The response will contain a URL to the Stripe checkout form to collect credit card details.

See the [Stripe Checkout API documentation](https://docs.stripe.com/api/checkout/sessions/create) for more details on the response fields.

## Invoicing (so Stripe does the invoicing) 
    ↳ self-serve? Charge automatically 
    ↳ enterprise customer? Send invioce 
    Note. can do BOTH and set up multiple billing profiles 4. Optional (?): let Stripe calculate tax

Stripe Invoicing is a global invoicing software platform built to save you time and get you paid faster. OpenMeter can synchronize invoices to Stripe Invoicing continuesly to automatically collect payments. Stripe Invoicing makes it easy to automate accounts receivable, collect payments, and reconcile transactions.

OpenMeter can synchronize invoices to Stripe Invoicing. This allows you to deliver invoices via Stripe and collect payments automatically. Stripe Invoicing makes it easy to automate tax calculations, accounts receivable, collect payments, and reconcile transactions.

{:.info}
> **Stripe fees:** Stripe will charge a fee for each invoice, tax calculations and payment according to your contract with them. Please see the Stripe Fees page for more information.

When you have the Stripe app installed and set as a billing profile, OpenMeter will automatically synchronize invoices to Stripe Invoicing. OpenMeter will create a Stripe Invoice for each OpenMeter invoice and mark invoices finalize to kick of the payment collection in Stripe.

You can have multiple billing profiles with OpenMeter. This is useful if you have different payment collection methods for different customers. For example, you can have a billing profile for self-service customers with automatic payment collection and a billing profile for enterprise customers with email invoicing.

You can configure the payment collection method in the Billing Profile. OpenMeter supports two payment collection methods with Stripe:

1. Charge Automatically: (default) OpenMeter will tell Stripe to collect charges with the default payment method for the customer. Great for self service use-cases.
1. Send Invoice: OpenMeter will tell Stripe to email the invoice to the customer with the payment instructions. Great for enterprise clients.

To be able to collect charges automatically, you need to have a default payment method set the customer.

{:.info}
> **Customer Default Payment Method**
> When you add a payment method to a customer in OpenMeter, that method becomes the default. However, if you leave the payment method field in OpenMeter blank, OpenMeter will fall back to the default payment method set in Stripe (if any).

To send an invoice, you need to have an email address set for the Stripe Customer.

{:.info}
> **Invoicing Email**<br>
> Unfortunately, Stripe does not provide an API to set the email address for invoices. So you need to make sure to set the email address for the Stripe Customer via the Stripe Dashboard. The email address on the OpenMeter Customer will be ignored with Stripe Invoicing.

When a paid subscription is created, OpenMeter will enforce that a customer linked with Stripe has either a default payment method or an email address depending on the collection method settings.

If you have both self-service and enterprise clients, you can create a separate billing profile for each group and configure the payment collection method appropriately. Then you can set the self-service billing profile the default and link enterprise customers to the enterprise billing profile. This way your self service clients will be charged automatically and your enterprise clients will receive an email invoice.

### Timing of Invoices

When an invoice is sent to your end customer depends on both OpenMeter and Stripe settings. These two factors determine how long the system waits before finalizing and delivering the invoice.

#### OpenMeter Billing Profile Settings

OpenMeter controls how long to wait for usage events before creating an invoice:

**Wait for Late Usage Events**

How long OpenMeter should delay invoice generation to account for delayed or out-of-order usage. Set to P0D to include only events already received (immediate generation).

{:.warning}
> Important: Ingest delays can cause incorrect invoice amounts.

**Wait Before Sending Invoices**
Additional wait time after the invoice is generated. Set to P0D to send immediately after processing.

See: [Billing Profiles](/metering-and-billing/billing-invoicing-subscriptions/#billing-profiles)

#### Stripe Invoice Finalization Settings

Stripe applies its own timing rules when finalizing and sending invoices.
By default, Stripe waits one hour before finalizing an invoice.

You can adjust this grace period in Stripe:

Stripe Dashboard → Settings → Billing → Invoices → Invoice Finalization

## Optional: Automatic Tax Calculation

Leverage Stripe Tax to handle complex tax rules and rates for any region. The integration ensures accurate, up-to-date tax calculations for each invoice, removing the guesswork and reducing compliance risks.

Stripe calculates tax based on:
* Vendor location
* Customer location
* Product tax code (global default or per rate card)

{:.info}
> **Defining tax codes:** To define tax codes for rate cards, you can set default tax codes in Billing Settings. You can also specify tax codes per rate card by editing the product catalog when creating a plan.

You can enable automatic tax calculation for your invoices using Stripe as a payment provider. Tax calculation is based on the customer's situation, location, product type, and other factors, so always consult a tax professional.

To enable automatic tax calculation in Stripe, make sure:

* You consult a tax professional to ensure you comply with tax laws.
* You configured tax on your Stripe account. https://dashboard.stripe.com/settings/tax
* You reviewed default [tax settings](https://dashboard.stripe.com/settings/tax) in your Stripe account.
* You installed the Stripe App in OpenMeter
* You set the Stripe App to be the default default billing profile
* You collect tax information from your Customers at onboarding (address, VAT number, etc.)
* You can use the Stripe Checkout Session to collect tax information from your customers.

You can read more about Stripe Tax in their documentation. https://docs.stripe.com/tax

## Optional: Customer Portal Session

You can create a [Stripe Portal Session](https://docs.stripe.com/customer-management) to allow customers to manage their payment methods and download their invoice history.

The Stripe Portal Session allows customers to:

* Manage their payment methods
* Change billing address
* Download their invoice history

### Create a Stripe Portal Session

The session will contain a URL to the Stripe Portal. The customer can use this URL to manage their payment methods and download their invoice history.

```sh
curl --request POST \
  --url https://us.api.konghq.com/v3/openmeter/customers/01G65Z755AFWAKHE12NY0CQ9FH/billing/stripe/portal-sessions \
  --header 'Accept: application/json, application/problem+json' \
  --header 'Authorization: Bearer YOUR_KONNECT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{
    "stripe_options": {
      "returnURL": "https://your-app.com/portal"
    }
  }'
```

