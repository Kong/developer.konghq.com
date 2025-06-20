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
  a: Create a transit gateway in AWS and create a resources share to share the transit gateway with the AWS account linked to your {{site.konnect_short_name}} account, then create a [`KonnectCloudGatewayTransitGateway`](/operator/reference/custom-resources/#konnectcloudgatewaytransitgateway) and accept the transit gateway attachment in AWS.

faqs:
  - q: Can I create a {{site.konnect_short_name}} Transit Gateway linked to an Azure virtual network?
    a: Yes, refer to [Azure peering](/dedicated-cloud-gateways/azure-peering/) to learn how to configure your VNET Peering App on Azure, then configure the [`KonnectCloudGatewayTransitGateway`](/operator/reference/custom-resources/#konnectcloudgatewaytransitgateway) resource with the [`azureTransitGateway`](/operator/reference/custom-resources/#azuretransitgateway) field.

related_resources:
  - text: AWS Transit Gateway peering
    url: /dedicated-cloud-gateways/transit-gateways/
  - text: Azure peering
    url: /dedicated-cloud-gateways/azure-peering/
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
---

## Create a transit gateway in AWS

Use this command to create a transit gateway in AWS:
```sh
aws ec2 create-transit-gateway
```

{:.warning}
> Make sure to create the transit gateway in the same region as the {{site.konnect_short_name}} network provider. You can set the region in the [AWS CLI configuration](#aws-cli) or use the `--region` flag in each command.

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

Create your Transit Gateway in {{site.konnect_short_name}} with the [`KonnectCloudGatewayTransitGateway`](/operator/reference/custom-resources/#konnectcloudgatewaytransitgateway) resource:

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

Accept the transit gateway attachment:
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

