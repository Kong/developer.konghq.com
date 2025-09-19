---
title: Configure private hosted zones for Dedicated Cloud Gateway
description: 'Enable private DNS resolution for your Dedicated Cloud Gateway using either a private hosted zone or an Outbound DNS Resolver.'
content_type: how_to
permalink: /dedicated-cloud-gateways/private-hosted-zones/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
    - gateway
api_specs: 
  - konnect/cloud-gateways
works_on:
    - konnect

tldr:
  q: How do I configure a Private Hosted Zone for my Dedicated Cloud Gateway?
  a: Use the AWS CLI to authorize VPC association, then call the {{site.konnect_short_name}} API to attach the hosted zone for private DNS resolution.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Outbound DNS resolver
    url: /dedicated-cloud-gateways/outbound-dns-resolver/
  - text: Amazon VPC Documentation
    url: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
prereqs:
  skip_product: true
  inline:
  - title: "Dedicated Cloud Gateway"
    include_content: prereqs/dedicated-cloud-gateways
  - title: "AWS CLI"
    include_content: prereqs/aws-cli
  - title: "AWS private hosted zone"
    content: |
      This tutorial requires:
      - An AWS subscription with access to [private hosted zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-creating.html)
      - Permission to run `route53:create-vpc-association-authorization`
      - A VPC in your AWS account to associate with the zone

      You'll also need the following information:
      - Your `hosted-zone-id`
      - Your `VPCRegion`
      - Your `VPCId`

      Create environment variables to store these credentials:

      ```sh
      export AWS_HOSTED_ZONE_ID='YOUR_HOSTED_ZONE_ID'
      export AWS_VPC_REGION='YOUR_VPC_REGION'
      export AWS_VPC_ID='YOUR_VPC_ID'
      ```

automated_tests: false
---


## Associate {{site.konnect_short_name}} with your private hosted zone

Using the AWS CLI, create an associate between the hosted zone and the VPC:

```sh
aws route53 create-vpc-association-authorization \
  --hosted-zone-id Z082811935OXJB57VZOSV \
  --vpc VPCRegion=us-east-2,VPCId=$AWS_VPC_ID
```


## Create the Private DNS config

Connect the Dedicated Cloud Gateway to an AWS Route 53 private hosted zone:

{% navtabs "configure-dns" %}
{% navtab "Cloud Gateways API" %}

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/private-dns
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: $AWS_PRIVATE_DNS_NAME
  private_dns_attachment_config:
    kind: aws-private-hosted-zone-attachment
    hosted_zone_id: $AWS_HOSTED_ZONE_ID
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Konnect UI" %}

1. In the {{site.konnect_short_name}} UI, navigate to [**Networks**](https://cloud.konghq.com/global/networks/) in the sidebar.
1. Click the settings icon next to your AWS network, and select **Configure private DNS** from the dropdown menu.
1. Enter `dev-hosted-zone` in the **Private hosted zone name** field.
1. Enter your AWS hosted zone ID in the **Hosted zone ID** field. For example: `Z9237512550OTOW57VYEW`
1. Click **Save**.

{% endnavtab %}
{% endnavtabs %}

## Validation

After a few moments, your private hosted zone will be associated with the Dedicated Cloud Gateway VPC and ​​you can now resolve requests over the VPC peering connection. To validate that everything was configured correctly, issue a `GET` request to the [`/private-dns`](/api/konnect/control-planes/#/operations/private-networks) endpoint to retrieve zone information:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/private-dns
status_code: 200
region: global
method: GET
{% endkonnect_api_request %}
<!--vale on-->
