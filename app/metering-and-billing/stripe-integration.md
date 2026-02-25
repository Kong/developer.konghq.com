---
title: "Collect payments with Stripe"
content_type: reference
description: "Learn how to collect revenue with Stripe Invoicing, Stripe Tax and Stripe Payments with the {{site.metering_and_billing}} Stripe integration."
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

You can integrate Stripe Invoicing with Konnect {{site.metering_and_billing}} to:

* Deliver invoices to customers via Stripe Invoicing
* Charge credit cards and automate revenue collection via Stripe Payments
* Enable automatic sales tax calaculation via Stripe tax
* Support multiple payment methods and currencies including crypto

## Revenue Lifecycle

The following table shows which parts of the revenue lifecycle is handled by Konnect {{site.metering_and_billing}}, Stripe Invoicing, Stripe Tax and Stripe Payments:

| Revenue Lifecycle             | Metering & Billing |          Stripe          |
| :---------------------------- | :----------------: | :----------------------- |
| Usage metering                |         ✅         |                          |
| Products and prices           |         ✅         |                          |
| Subscription management       |         ✅         |                          |
| Billing and subscriptions     |         ✅         |                          |
| Rating and invoice generation |         ✅         |                          |
| Tax calculations (if enabled) |                    |  ✅ (Stripe Tax)         |
| Sending invoices to customers |                    |  ✅ (Stripe Invoicing)   |
| Storing credit card details   |                    |  ✅ (Stripe Payments)    |
| Payment collection            |                    |  ✅ (Stripe Payments)    |

## How to setup Stripe with {{site.metering_and_billing}}

Configuring {{site.metering_and_billing}} with Stripe involves the following steps:
1. Install the Stripe app in {{site.metering_and_billing}}.
   1. Configure how you want to collect invoices with a billing profile.
   1. (Optional) Configure tax collection.
1. Configure existing or new customers from Stripe in {{site.metering_and_billing}}.
1. (Optional) Create an additional billing profile so you can automatically and manually collect invoices.
1. (Optional) Create a customer portal session.

## Invoicing 

When you configure the Stripe app in {{site.metering_and_billing}}, {{site.konnect_short_name}} uses [Stripe Invoicing](https://stripe.com/invoicing) to synchronize and deliver invoices, automate tax calculations (if configured), and reconcile transactions. 

{{site.metering_and_billing}} supports two payment collection methods with Stripe:
1. **Charge Automatically (default):** {{site.metering_and_billing}} will tell Stripe to collect charges with the default payment method for the customer. This method works well for self service use cases. To collect charges automatically, you need to have a default payment method set for customer.
   
   {:.info}
   > **Customer Default Payment Method**
   > When you add a payment method to a customer in {{site.metering_and_billing}}, that method becomes the default. However, if you leave the payment method field in {{site.metering_and_billing}} blank, {{site.metering_and_billing}} will fall back to the default payment method set in Stripe (if any).
1. **Send Invoice:** {{site.metering_and_billing}} will tell Stripe to email the invoice to the customer with the payment instructions. This method works well for enterprise clients. To send an invoice, you need to have an email address set for the Stripe customer.
   
   {:.info}
   > **Invoicing Email**<br>
   > Unfortunately, Stripe does not provide an API to set the email address for invoices. So you need to make sure to set the email address for the Stripe Customer via the Stripe Dashboard. The email address on the {{site.metering_and_billing}} Customer will be ignored with Stripe Invoicing.

You can use one or both methods by setting up one or more billing profiles. This is useful if you have different payment collection methods for different customers. For example, you can have a billing profile for self-service customers with automatic payment collection and a billing profile for enterprise customers with email invoicing. You can set the self-service billing profile as the default and link enterprise customers to the enterprise billing profile. This way your self-service customers are charged automatically and your enterprise clients will receive an email invoice.

When the Stripe app is installed and set as a [billing profile](/metering-and-billing/billing-invoicing-subscriptions/#billing-profiles), {{site.metering_and_billing}} will automatically synchronize invoices to Stripe Invoicing. {{site.metering_and_billing}} will create a Stripe Invoice for each {{site.metering_and_billing}} invoice and mark invoices as finalized to kick of the payment collection in Stripe.

When a paid subscription is created, {{site.metering_and_billing}} will enforce that a customer linked with Stripe has either a default payment method or an email address depending on the collection method settings.

{:.info}
> **Stripe fees:** Stripe will charge a fee for each invoice, tax calculations and payment according to your contract with them. See [Stripe Fees](https://stripe.com/pricing) for more information.

### Invoice timing

When an invoice is sent to your end customer depends on both {{site.metering_and_billing}} and Stripe settings. These two factors determine how long the system waits before finalizing and delivering the invoice.

The {{site.metering_and_billing}} billing profile controls how long to wait for usage events before creating an invoice:
* **Wait for Late Usage Events:** How long {{site.metering_and_billing}} should delay invoice generation to account for delayed or out-of-order usage. Set to `P0D` to include only events already received (immediate generation).

  {:.warning}
  > **Important:** Ingest delays can cause incorrect invoice amounts.
* **Wait Before Sending Invoices:** Additional wait time after the invoice is generated. Set to `P0D` to send immediately after processing.

{:.info}
> **Stripe applies its own timing rules** when finalizing and sending invoices.
By default, Stripe waits one hour before finalizing an invoice.<br/>
You can adjust this grace period in the [invoice settings](https://docs.stripe.com/invoicing/scheduled-finalization) in Stripe.

## (Optional) Automatic tax calculation

You can enable automatic tax calculation for your invoices using Stripe as a payment provider. Tax calculation is based on the customer's situation, location, product type, and other factors, so always consult a tax professional. You can use [Stripe Tax](https://stripe.com/tax) to handle complex tax rules and rates for any region. The integration ensures accurate, up-to-date tax calculations for each invoice, removing the guesswork and reducing compliance risks.

Stripe calculates tax based on:
* Vendor location
* Customer location
* Product tax code (global default or per [rate card](/metering-and-billing/product-catalog/#rate-cards))

  {:.info}
  > **Defining tax codes:** To define tax codes for rate cards, you can set default tax codes in the [billing settings in {{site.konnect_short_name}}](https://cloud.konghq.com/us/metering-billing/billing-profiles). You can also specify tax codes per rate card by editing the product catalog when creating a plan.

To enable automatic tax calculation in Stripe, make sure:

* Consult a tax professional to ensure you comply with tax laws.
* [Configure tax](https://dashboard.stripe.com/settings/tax) on your Stripe account.
* Review the default [tax settings](https://dashboard.stripe.com/settings/tax) in your Stripe account.
* [Installed the Stripe app in {{site.metering_and_billing}}](#install-the-stripe-integration-in-sitemetering_and_billing)
* Set the Stripe app as the default billing profile
* Collect tax information from your customers at onboarding (for example: address and VAT number)
* Optionally use the Stripe Checkout Session to collect tax information from your customers

For more information, see the [Stripe Tax](https://docs.stripe.com/tax) documentation.

## Install the Stripe integration in {{site.metering_and_billing}}

Before you install the Stripe integration in {{site.metering_and_billing}}, copy and save your Stripe API key from your dashboard.

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
1. If you want to configure Stripe to collect taxes, click **Advanced Customize Billing Profile** and configure tax settings in the Tax Collection section.
1. Click **Create Billing Profile**.
1. Do one of the following:
   * To set this as the default billing profile, click **Start Billing**.
   * To not set this as the default billing profile, disable **Set this as the new default billing profile** and click **Keep Current Default Profile**.


## Configure Stripe customers in {{site.metering_and_billing}}

You can create customers in {{site.metering_and_billing}} from existing customers in Stripe or from customers that don't exist in Stripe. 

{% navtabs "customers" %}
{% navtab "Existing customer" %}
To connect an existing Stripe customer to an {{site.metering_and_billing}} customer, you must have a [customer in Stripe](https://docs.stripe.com/billing/customer) already.

{:.info}
> **Default payment method:** Be sure that you also set the Stripe default payment method ID in {{site.metering_and_billing}} or set a default payment method in Stripe for the customer. This is necessary to automatically charge the customer when an invoice is created.

1. In the {{site.konnect_short_name}} sidebar, click **{{site.metering_and_billing}}**.
1. In the {{site.metering_and_billing}} sidebar, click **Billing**.
1. Click **Create Customer**.
1. In the **Name** field, enter `Stripe`.
1. If you are sending invoices to customers, enter their email in the **Primary Email** field.
1. Expand the Billing Profile settings.
1. In the **Stripe Customer ID** field, enter the customer's ID from Stripe. For example: `cus_U12Ixxxxxx`
1. In the **Payment Method ID** field, enter the payment method ID for the customer in Stripe. For example: `pm_1T30Kp4bZcDnpr9o3eBRrh7B`
   
   You can find the payment method by navigating to the customer in Stripe, clicking the action menu next to the payment method, and clicking **Copy ID**.
1. Click **Save**.

You can also configure the Stripe settings for a customer in {{site.metering_and_billing}} by sending a PUT request to the [`/openmeter/customers/{customerId}/billing` endpoint](/api/konnect/metering-and-billing/v3/#/operations/upsert-customer). 
{% endnavtab %}
{% navtab "Non-existing customer (checkout session)" %}
{{site.metering_and_billing}} provides an API to create a customer and generate a [Stripe Checkout](https://stripe.com/payments/checkout) link to collect payment details. When a customer completes the checkout form and provides their payment method, {{site.metering_and_billing}} will automatically set the Stripe customer ID and the payment method to the default payment method for the {{site.metering_and_billing}} customer. To do this, {{site.metering_and_billing}} listens to the `setup_intent.succeeded` event via webhooks. This webhook is setup automatically when the {{site.metering_and_billing}} Stripe app is installed.

Generate a Stripe Checkout URL to the payment form by send a POST request to the [`/openmeter/customers/{customerId}/billing/stripe/checkout-sessions` endpoint](/api/konnect/metering-and-billing/v3/#/operations/create-customer-stripe-checkout-session):
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/billing/stripe/checkout-sessions
status_code: 201
method: POST
region: us
body:
  stripe_options:
    success_url: https://example.com/success
    cancel_url: https://example.com/cancel
  customer:
    name: ACME, Inc.
    currency: USD
    usageAttribution:
      subjectKeys:
        - subject-123
  options:
    mode: setup
{% endkonnect_api_request %}
<!--vale on-->
  
The session operates in “setup” mode, which collects payment details without charging
the customer immediately. The collected payment method can be used for future
subscription billing.

For hosted checkout sessions, redirect customers to the returned URL. For embedded
sessions, use the `client_secret` to initialize Stripe.js in your application.

The response will contain a URL to the Stripe checkout form to collect credit card details.

See the [Stripe Checkout API documentation](https://docs.stripe.com/api/checkout/sessions/create) for more details on the response fields.
{% endnavtab %}
{% endnavtabs %}

## (Optional) Create a customer Stripe Portal Session

You can create a [Stripe Portal Session](https://docs.stripe.com/customer-management) to allow customers to manage their payment methods and download their invoice history. The session will contain a URL to the Stripe Portal.

The Stripe Portal Session allows customers to:

* Manage their payment methods
* Change billing address
* Download their invoice history


To create a Stripe Portal Session for customers, send a POST request to the [`/openmeter/customers/{customerId}/billing/stripe/portal-sessions` endpoint](/api/konnect/metering-and-billing/v3/#/operations/create-customer-stripe-portal-session):
<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID/billing/stripe/portal-sessions
status_code: 201
method: POST
region: us
body:
  stripe_options:
    returnURL: https://your-app.com/portal
{% endkonnect_api_request %}
<!--vale on-->