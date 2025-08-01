---
title: 'Moesif API Monetization and Analytics'
name: 'Moesif API Monetization and Analytics'

content_type: plugin

publisher: moesif
description: "Powerful API analytics and usage-based billing to monetize APIs"

products:
    - gateway

works_on:
    - on-prem
    - konnect

third_party: true

support_url: mailto:support@moesif.com

source_code_url: https://github.com/Moesif/kong-plugin-moesif

license_url: https://raw.githubusercontent.com/Moesif/kong-plugin-moesif/master/LICENSE

privacy_policy_url: https://www.moesif.com/privacy?utm_medium=docs&utm_campaign=partners&utm_source=kong

terms_of_service_url: https://www.moesif.com/terms?utm_medium=docs&utm_campaign=partners&utm_source=kong

icon: moesif.png

search_aliases:
  - kong-plugin-moesif
  - Moesif
  - Moesif API Analytics
  - Moesif API Monetization

related_resources:
  - text: Moesif documentation
    url: https://www.moesif.com/docs/server-integration/kong-api-gateway/
  - text: Troubleshooting Kong with Moesif
    url: https://www.moesif.com/docs/server-integration/kong-api-gateway/#troubleshooting?language=kong-api-gateway&utm_medium=docs&utm_campaign=partners&utm_source=kong

min_version:
  gateway: '1.0'
---

The Moesif plugin helps you understand [customer API usage](https://www.moesif.com/features/api-analytics?utm_medium=docs&utm_campaign=partners&utm_source=kong&language=kong-api-gateway) and monetize your APIs with [usage-based billing](https://www.moesif.com/solutions/metered-api-billing?utm_medium=docs&utm_campaign=partners&utm_source=kong&language=kong-api-gateway)
by logging API traffic to [Moesif API Monetization and Analytics](https://www.moesif.com?language=kong-api-gateway&utm_medium=docs&utm_campaign=partners&utm_source=kong). 

Moesif enables you to:

* [Analyze customer API usage](https://www.moesif.com/features/api-analytics?utm_medium=docs&utm_campaign=partners&utm_source=kong)
* [Get alerted of issues](https://www.moesif.com/features/api-monitoring?utm_medium=docs&utm_campaign=partners&utm_source=kong)
* [Monetize APIs with usage-based billing](https://www.moesif.com/solutions/metered-api-billing?utm_medium=docs&utm_campaign=partners&utm_source=kong)
* [Enforce quotas and contract terms](https://www.moesif.com/features/api-governance-rules?utm_medium=docs&utm_campaign=partners&utm_source=kong)
* [Guide users](https://www.moesif.com/features/user-behavioral-emails?utm_medium=docs&utm_campaign=partners&utm_source=kong)

This plugin supports automatic analysis of high-volume REST, GraphQL, XML/SOAP, and other APIs without adding latency.

## How it works

This plugin logs API traffic to
[Moesif API Analytics and Monetization](https://www.moesif.com/?language=kong-api-gateway&utm_medium=docs&utm_campaign=partners&utm_source=kong). 
It batches data and leverages an [asynchronous design](https://www.moesif.com/enterprise/api-analytics-infrastructure?language=kong-api-gateway&utm_medium=docs&utm_campaign=partners&utm_source=kong) to ensure no latency is added to your API.

Moesif natively supports REST, GraphQL, Web3, SOAP, JSON-RPC, and more. 
Moesif is SOC 2 Type 2 compliant and has features like [client-side encryption](https://www.moesif.com/enterprise/security-compliance?language=kong-api-gateway&utm_medium=docs&utm_campaign=partners&utm_source=kong) so data stays private to your organization.

## Install the Moesif plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="--server=http://luarocks.org/manifests/moesif kong-plugin-moesif" %}

For all plugin versions, see the [package on Luarocks](http://luarocks.org/modules/moesif/kong-plugin-moesif).

{:.info}
> If you are using the [{{site.kic_product_name}}](/kubernetes-ingress-controller/), the installation is slightly different. 
> Review the [custom plugin docs for the {{site.kic_product_name}}](/kubernetes-ingress-controller/custom-plugins/).

## Identifying users

This plugin automatically identifies API users so you can associate a user's API traffic to user data and other app analytics.
The default algorithm covers most authorization designs and works as follows, by order of precedence:

1. If the [`config.user_id_header`](./reference/#schema--config-user-id-header) option is set, read the value from the specified HTTP header key in `config.user_id_header`.
2. Else, if {{site.base_gateway}} has a value defined for `x-consumer-custom-id`, `x-consumer-username`, or `x-consumer-id` (in that order), use that value.
3. Else, if an authorization token is present in [`config.authorization_header_name`](./reference/#schema--config-authorization-header-name), parse the user ID from the token as follows:
   * If header contains `Bearer`, base64-decode the string and use the value defined by [`config.authorization_user_id_field`](./reference/#schema--config-authorization-user-id-field) (default value is `sub`).
   * If header contains `Basic`, base64-decode the string and use the username portion (before the `:` character).

For advanced configurations, you can define a custom header containing the user ID via [`config.user_id_header`](./reference/#schema--config-user-id-header) or override the options [`config.authorization_header_name`](./reference/#schema--config-authorization-header-name) and [`config.authorization_user_id_field`](./reference/#schema--config-authorization-user-id-field).

## Identifying companies

You can associate API users to companies for tracking account-level usage similar to user-level usage. 
This can be done in one of the following ways, by order of precedence:
1. Define [`config.company_id_header`](./reference/#schema--config-company-id-header). Moesif will use the value present in that header. 
2. Else, use the Moesif [update user API](https://www.moesif.com/docs/api#update-a-user) to set a `company_id` for a user. Moesif will associate the API calls automatically.
3. Else, if an authorization token is present in [`config.authorization_header_name`](./reference/#schema--config-authorization-header-name), parse the company ID from the token as follows:
   * If header contains `Bearer`, base64-decode the string and use the value defined by [`config.authorization_company_id_field`](./reference/#schema--config-authorization-company-id-field) (default value is `null`).

See the Moesif documentation for [more info on identifying customers](https://www.moesif.com/docs/getting-started/identify-customers/?language=kong-api-gateway&utm_medium=docs&utm_campaign=partners&utm_source=kong).
