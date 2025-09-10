---
title: Set up an AWS VPC peering connection
description: 'Use the {{site.konnect_short_name}} Cloud Gateways API to create a VPC peering connection with your AWS VPC.'
content_type: how_to
permalink: /dedicated-cloud-gateways/aws-vpc-peering/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I set up an AWS VPC peering connection with my Dedicated Cloud Gateway using the API?
  a: Use the {{site.konnect_short_name}} API to initiate peering, then accept the request in AWS and update your route table.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: AWS VPC Peering Documentation
    url: https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways

    - title: "AWS credentials and VPC"
      content: |
        You'll need:

        - An AWS account with [permission to accept VPC peering requests](https://docs.aws.amazon.com/vpc/latest/peering/security-iam.html#vpc-peering-iam-accept) and update route tables
        - A target AWS VPC ID
        - The AWS region of your VPC
        - The VPC's CIDR block

        Save these values:

        ```sh
        export AWS_ACCOUNT_ID='123456789012'
        export AWS_VPC_ID='vpc-0f1e2d3c4b5a67890'
        export AWS_REGION='us-east-2'
        export AWS_VPC_CIDR='10.1.0.0/16'
        ```

---

## Initiate the VPC peering connection

Send the following request to the Cloud Gateways API:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: us-east-2 vpc peering
  cidr_blocks:
    - $AWS_VPC_CIDR
  transit_gateway_attachment_config:
    kind: aws-vpc-peering-attachment
    peer_account_id: $AWS_ACCOUNT_ID
    peer_vpc_id: $AWS_VPC_ID
    peer_vpc_region: $AWS_REGION
{% endkonnect_api_request %}
<!--vale on-->


## Accept the peering request in AWS

1. Go to the AWS Console → **VPC** → **VPC Peering Connections**.
1. Locate the pending request from {{site.konnect_short_name}}.
1. Select the request and from the Actions menu, select **Accept request**.

## Update your AWS route table

1. In the AWS Console, go to **VPC** → **Route Tables**.
1. Select the route table for your VPC's subnet.
1. Select **Edit routes** from the Actions menu.
1. Click **Add route**, and enter the following:
    - **Destination**: The CIDR block of the {{site.konnect_short_name}} network.
    - **Target**: The accepted VPC peering connection.
1. Save your changes.

This ensures private traffic routing between your VPC and the Dedicated Cloud Gateway.

## Validation

To validate that everything was configured correctly, issue a `GET` request to the [`/transit-gateways`](/api/konnect/control-planes/#/operations/list-transit-gateways) endpoint to retrieve VPC peering information:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways
status_code: 200
region: global
method: GET
{% endkonnect_api_request %}
<!--vale on-->
