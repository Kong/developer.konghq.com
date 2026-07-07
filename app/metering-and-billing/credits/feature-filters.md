---
title: "Feature filters"
content_type: reference
beta: true
description: "Restrict credit grants to specific product features and query balances or transaction history scoped to a single feature."
layout: reference
products:
  - metering-and-billing
works_on:
  - konnect
breadcrumbs:
  - /metering-and-billing/
  - /metering-and-billing/credits/
tags:
  - billing
  - credits
related_resources:
  - text: "Credit balance model"
    url: /metering-and-billing/credits/balance-model/
  - text: "Credit grants"
    url: /metering-and-billing/credits/grants/
  - text: "Credit consumption and expiration"
    url: /metering-and-billing/credits/consumption-and-expiration/
  - text: "Credit transaction history"
    url: /metering-and-billing/credits/transaction-history/
  - text: "Operational flows"
    url: /metering-and-billing/credits/operational-flows/
  - text: "Correctness guarantees"
    url: /metering-and-billing/credits/correctness-guarantee/
  - text: "Get started with prepaid credits"
    url: /how-to/get-started-with-prepaid-credits/
next_steps:
  - text: Get started with prepaid credits
    url: /how-to/get-started-with-prepaid-credits/
---

Feature filters let you restrict a [credit grant](/metering-and-billing/credits/grants/) to specific product features and query balances or transaction history scoped to a single feature.
Use them when you need to track or display how much credit is available for a particular feature, such as `input_tokens` or `output_tokens`.

## How feature balances work

A feature balance represents the total credit available for a specific product feature.

The available balance includes the following types of credits:
* **Restricted credits**: Can only be consumed by charges for the features listed on the grant.
* **Unrestricted (shared) credits**: Have no feature restriction and can be consumed by any feature.

A feature balance includes both restricted credits for that feature and unrestricted shared credits, because both are available to spend on it.
Not all credit in a feature balance view is restricted to that feature.

You can apply only one operator to `filter[feature_key]` per request.

## Restricting grants to features

When you create a [credit grant](/metering-and-billing/credits/grants/), `filters.features` controls which features can use that credit.

<!--vale off-->
{% table %}
columns:
  - title: "`filters.features` example value"
    key: value
  - title: Meaning
    key: meaning
rows:
  - value: "Omitted or empty"
    meaning: "The credit is unrestricted and can be used for any feature."
  - value: |
      `["input_tokens"]`
    meaning: "The credit can only be used for the specified feature, for example: `input_tokens`."
  - value: |
      `["input_tokens", "output_tokens"]`
    meaning: "The credit can be used for any of the listed features."
{% endtable %}
<!--vale on-->

## Querying by feature

Use `filter[feature_key]` to scope a query to one or more features.
The filter syntax is the same for the balance and transaction endpoints.

<!--vale off-->
{% table %}
columns:
  - title: Operator
    key: operator
  - title: Syntax
    key: syntax
  - title: Returns
    key: returns
rows:
  - operator: "None (omitted)"
    syntax: "—"
    returns: "All credits or transactions, regardless of feature."
  - operator: "`eq`"
    syntax: "`filter[feature_key][eq]=input_tokens`"
    returns: "Credits or transactions relevant to `input_tokens`, including shared unrestricted credits."
  - operator: "`oeq`"
    syntax: "`filter[feature_key][oeq]=input_tokens,output_tokens`"
    returns: "Credits or transactions for any of the listed features."
  - operator: "`neq`"
    syntax: "`filter[feature_key][neq]=input_tokens`"
    returns: "Credits or transactions not matching the specified feature, for example: `input_tokens`.."
  - operator: "`contains`"
    syntax: "`filter[feature_key][contains]=tokens`"
    returns: "Credits or transactions where the feature key contains the string."
  - operator: "`ocontains`"
    syntax: "`filter[feature_key][ocontains]=input,output`"
    returns: "Credits or transactions where the feature key contains any of the strings."
{% endtable %}
<!--vale on-->

When you query by feature, the balance or transaction results include:

- Unrestricted shared credits
- Credits restricted to that specific feature
- Credits restricted to a set that contains that feature

For example, using `filter[feature_key][eq]=input_tokens`:

<!--vale off-->
{% table %}
columns:
  - title: Credit grant
    key: grant
  - title: "Included in `input_tokens` balance?"
    key: included
rows:
  - grant: "Unrestricted"
    included: "Yes"
  - grant: |
      `["input_tokens"]`
    included: "Yes"
  - grant: |
      `["input_tokens", "output_tokens"]`
    included: "Yes"
  - grant: |
      `["storage"]`
    included: "No"
{% endtable %}
<!--vale on-->

### Examples

In the following examples, replace `{customerID}` with the customer's ID.
The customer name and key aren't accepted in this path parameter.
To find a customer ID, send a GET request to the [`/openmeter/customers`](/api/konnect/metering-and-billing/v3/#/operations/get-customer) endpoint, or check the URL of the customer's profile in the {{site.konnect_short_name}} UI.

Filter parameters must be percent-encoded in the URL: use `%5B` for `[` and `%5D` for `]`.
For example, `filter[feature_key][eq]` becomes `filter%5Bfeature_key%5D%5Beq%5D`.

Query the credit balance for a specific feature:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/{customerID}/credits/balance?filter%5Bfeature_key%5D%5Beq%5D=input_tokens
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

Query the transaction history for a specific feature:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/{customerID}/credits/transactions?filter%5Bfeature_key%5D%5Beq%5D=input_tokens
method: GET
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->