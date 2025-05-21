---
title: Configure private hosted zones for Dedicated Cloud Gateway
description: 'Enable private DNS resolution for your Dedicated Cloud Gateway using either a private hosted zone or an Outbound DNS Resolver.'
content_type: how_to
permalink: /dedicated-cloud-gateways/private-hosted-zones/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
    - gateway

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
  - title: "Dedicated Cloud Gateways"
    content: |
      This tutorial requires a working Dedicated Cloud Gateways instance. 
      You'll also need the following information from the network: 
        * `VPCID`
        * `network-id`
        You can retrieve that using the following endpoint: 

        {% control_plane_request %}
        url: /v2/cloud-gateways/networks
        {% endcontrol_plane_request %}
        Save the desired values as environment variables:
        ```sh
        export DCGW_VPC_ID='YOUR_DCGW_VPC_ID'
        export NETWORK='YOUR_DCGW_NETWORK_ID'
        ```


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

---


## Associate {{site.konnect_short_name}} with your private hosted zone

Using the AWS CLI, create an associate between the hosted zone and the VPC:

```sh
aws route53 create-vpc-association-authorization \
  --hosted-zone-id Z1234567890ABCDEXAMPLE \
  --vpc VPCRegion=us-east-1,VPCId=$KONG_DCGW_VPC_ID
```


## Create the Private DNS config

Connect the Dedicated Cloud Gateway to an AWS Route 53 private hosted zone:

<!--vale off-->
{% control_plane_request %}
url: /v2/cloud-gateways/networks/$NETWORK_ID/private-dns
status_code: 201
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  name: us-east-2 private dns
  private_dns_attachment_config:
    kind: aws-private-hosted-zone-attachment
    hosted_zone_id: $AWS_HOSTED-ZONE-ID
{% endcontrol_plane_request %}
<!--vale on-->

## Validate

After a few moments, your private hosted zone will be associated with the Dedicated Cloud Gateway VPC and ​​you can now resolve `*.prod.internal` over the VPC peering or a Transit Gateway connection.