---
title: Create a Transit Gateway with {{ site.operator_product_name }} and AWS
description: "Create a KonnectCloudGatewayTransitGateway resource with {{ site.operator_product_name }} and AWS."
content_type: how_to


breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Cloud Gateways"

products:
  - operator

works_on:
  - konnect

tags:
  - aws

prereqs:
  inline: 
    - title: AWS account
      position: before
      content: |
          This tutorial requires an AWS account with permissions to create transit gateways and resource shares.
      icon_url: /assets/icons/aws.svg
    - title: AWS CLI
      position: before
      include_content: prereqs/aws-cli
      icon_url: /assets/icons/aws.svg

  operator:
    konnect:
      auth: true
      control_plane: true
      network: true

tldr:
  q: How can I create an AWS transit gateway and link it to {{site.konnect_short_name}} using {{ site.operator_product_name }}?
  a: Create a transit gateway in AWS and create a resources share to share the transit gateway with the AWS account linked to your {{site.konnect_short_name}} account, then create a `KonnectCloudGatewayTransitGateway` and accept the transit gateway attachment in AWS.
---

## Create a transit gateway in AWS

Use this command to create a transit gateway in AWS:
```sh
aws ec2 create-transit-gateway
```

Export the transit gateway ID and ARN to your environment:
```sh
export TRANSIT_GATEWAY_ID='YOUR TRANSIT GATEWAY ID'
export TRANSIT_GATEWAY_ARN='YOUR TRANSIT GATEWAY ARN'
```

## Create a resource share in AWS

Use this command to create a resource share:
```sh
aws ram create-resource-share --name transit-gateway-resource-share --resource-arns $TRANSIT_GATEWAY_ARN --principals $CLOUD_GATEWAY_PROVIDER_ID
```

Export the resource share ARN to your environment:
```sh
export RESOURCE_SHARE_ARN='YOUR RESOURCE SHARE ARN'
```

## Create the KonnectCloudGatewayTransitGateway resource

Create your Transit Gateway in {{site.konnect_short_name}}:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectCloudGatewayTransitGateway
apiVersion: konnect.konghq.com/v1alpha1
metadata:
 name: konnect-aws-transit-gateway-1
 namespace: kong
spec:
 networkRef:
   type: namespacedRef
   namespacedRef:
     name: konnect-network-1 
 type: AWSTransitGateway
 awsTransitGateway:
   name: "aws-transit-gateway-1"
   cidr_blocks:
   - "10.10.0.0/24"
   attachment_config:
     transit_gateway_id: '$TRANSIT_GATEWAY_ID'
     ram_share_arn: '$RESOURCE_SHARE_ARN'
{% endkonnect_crd %}
<!-- vale on -->

## Accept the transit gateway attachment in AWS

Fetch the list of transit gateway VPC attachments:
```sh
aws ec2 describe-transit-gateway-vpc-attachments
```
Retrieve the relevant attachment ID:
```sh
export ATTACHMENT_ID='YOUR AWS TRANSIT GATEWAY VPC ATTACHMENT ID'
```

Accept the Transit Gateway attachment:
```sh
aws ec2 accept-transit-gateway-vpc-attachment --transit-gateway-attachment-id $ATTACHMENT_ID
```

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectCloudGatewayTransitGateway
name: konnect-aws-transit-gateway-1
{% endvalidation %}
<!-- vale on -->

