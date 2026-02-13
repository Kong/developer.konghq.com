---
title: Configure an outbound DNS resolver for Dedicated Cloud Gateway
description: 'Forward DNS queries from your Dedicated Cloud Gateway to custom DNS servers using an outbound resolver.'
content_type: how_to
permalink: /dedicated-cloud-gateways/outbound-dns-resolver/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
    - gateway

works_on:
    - konnect

tldr:
  q: How do I configure an outbound DNS resolver for my Dedicated Cloud Gateway?
  a: Set up a Route 53 inbound resolver endpoint, then call the {{site.konnect_short_name}} API to forward specific domains to custom DNS servers.

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Route 53 Resolver Endpoints
    url: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-get-started.html
  - text: Amazon VPC Documentation
    url: /dedicated-cloud-gateways/aws-vpc-peering/
prereqs:
  skip_product: true
  inline:
  - title: "Dedicated Cloud Gateway"
    include_content: prereqs/dedicated-cloud-gateways
  - title: "AWS CLI"
    include_content: prereqs/aws-cli

  - title: "Amazon Route 53 inbound resolver endpoint"
    content: |
      You need to create an [inbound Route 53 resolver endpoint](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-get-started.html) in your VPC to receive DNS queries from your Dedicated Cloud Gateway.

      After creating the endpoint, collect the IP addresses assigned to it and the domain zones you want to forward.

      Save them in environment variables:
      ```sh
      export RESOLVER_IPS='10.0.0.10,10.1.0.53'
      export FORWARD_ZONES='example.internal.dev,example2.internal.dev'
      ```
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
automated_tests: false
---


## Connect the resolver to your Dedicated Cloud Gateway

Use the Konnect API to configure forwarding rules that send DNS queries to your resolver:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/private-dns
status_code: 201
method: POST
region: global
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: us-east-2 dns resolver
  private_dns_attachment_config:
    kind: aws-outbound-resolver
    dns_config:
      example.internal.dev:
        remote_dns_server_ip_addresses:
          - 10.0.0.10
      example2.internal.dev:
        remote_dns_server_ip_addresses:
          - 10.1.0.53
{% endkonnect_api_request %}
<!--vale on-->


## Validate

Once the resolver is configured, it may take a few minutes to become active, you can validate success by issuing a `GET` request to
[`/private-dns`](/api/konnect/cloud-gateways/#/operations/private-dns):

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/private-dns
status_code: 201
region: global
{% endkonnect_api_request %}
<!--vale on-->
