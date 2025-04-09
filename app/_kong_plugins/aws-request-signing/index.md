---
title: 'AWS Request Signing'
name: 'AWS Request Signing'

content_type: plugin

publisher: the-lego-group
description: 'Sign requests with AWS SIGV4 and temp credentials for secure use of AWS Lambdas in Kong'

products:
    - gateway

works_on:
    - on-prem

min_version:
    gateway: '3.4'

# on_prem:
#   - hybrid
#   - db-less
#   - traditional
# konnect_deployments:
#   - hybrid
#   - cloud-gateways
#   - serverless

third_party: true

license_type: Apache-2.0 (modified)

license_url: https://github.com/LEGO/kong-aws-request-signing/blob/main/LICENSE

support_url: https://github.com/LEGO/kong-aws-request-signing/issues

source_code_url: https://github.com/LEGO/kong-aws-request-signing

icon: aws-request-signing.png

search_aliases:
  - the lego group
  - aws-request-signing
---

The AWS Request Signing plugin allows for secure communication with AWS Lambdas. 
It signs requests with AWS SIGV4 and temporary credentials obtained from `sts.amazonaws.com` using an OAuth token.
This eliminates the need for an AWS API Gateway and simplifies the use of Lambdas as upstreams in {{site.base_gateway}}. 

## Install the AWS Request Signing plugin

### Prerequisites

To use this plugin, you have to prepare your AWS account.
Add your token issuer to the **Identity Providers** in your AWS account so that the plugin can request temporary credentials. 

For more information on the required AWS setup, visit the [plugin repo](https://github.com/LEGO/kong-aws-request-signing#aws-setup-required).

Once your AWS account is set up, you can use the plugin to communicate with your Lambda HTTPS endpoint.

### Install

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="https://github.com/LEGO/kong-aws-request-signing/raw/main/rocks/kong-aws-request-signing-$PLUGIN_VERSION.all.rock" explanation="Substitute `$PLUGIN_VERSION` with one of [available plugin versions](https://github.com/LEGO/kong-aws-request-signing/tree/main/rocks)." %}
