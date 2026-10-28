---
title: Create a Transit Gateway with {{ site.operator_product_name }} and AWS
permalink: /how-to/create-transit-gateway-with-operator-and-aws/
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
      network: true

cleanup:
  inline:
    - title: Clean up AWS resources
      content: |
        Delete the `KonnectCloudGatewayTransitGateway`, the resource share, and the transit gateway you created:

        ```bash
        kubectl delete -n kong konnectcloudgatewaytransitgateway konnect-aws-transit-gateway-1 --ignore-not-found
        aws ram delete-resource-share --resource-share-arn $RESOURCE_SHARE_ARN
        aws ec2 wait transit-gateway-available --transit-gateway-ids $TRANSIT_GATEWAY_ID
        aws ec2 delete-transit-gateway --transit-gateway-id $TRANSIT_GATEWAY_ID
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/aws.svg

tldr:
  q: How can I create an AWS transit gateway and link it to {{site.konnect_short_name}} using {{ site.operator_product_name }}?
  a: Create a transit gateway in AWS and create a resources share to share the transit gateway with the AWS account linked to your {{site.konnect_short_name}} account. Then, create a [`KonnectCloudGatewayTransitGateway`](/operator/reference/custom-resources/#konnectcloudgatewaytransitgateway) and accept the transit gateway attachment in AWS.

faqs:
  - q: Can I create a {{site.konnect_short_name}} Transit Gateway linked to an Azure virtual network?
    a: Yes, refer to [Azure peering](/dedicated-cloud-gateways/azure-peering/) to learn how to configure your VNET Peering App on Azure, then configure the [`KonnectCloudGatewayTransitGateway`](/operator/reference/custom-resources/#konnectcloudgatewaytransitgateway) resource with the [`azureTransitGateway`](/operator/reference/custom-resources/#azuretransitgateway) field.
  - q: I'm getting a `unable to create transit gateway with cidr block 10.10.0.0/24 because it overlaps with cidr blocks from an existing attachment` error when I try to validate my transit gateway resource, how do I fix it?
    a: This is caused by a CIDR block overlap. To resolve this, contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com).
related_resources:
  - text: AWS Transit Gateway peering
    url: /dedicated-cloud-gateways/transit-gateways/
  - text: Azure peering
    url: /dedicated-cloud-gateways/azure-peering/
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
---

## Create a KonnectGatewayControlPlane resource

Use the following command to create a Control Plane:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
  namespace: kong
spec:
  createControlPlaneRequest:
    name: gateway-control-plane
    cloud_gateway: true
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->

## Create a transit gateway in AWS

1. Use this command to create a transit gateway in AWS and save its output:
   ```sh
   aws ec2 create-transit-gateway > tgw.json
   ```
   {: data-test-step="block" }

   {:.warning}
   > **Notes:**
   > * If you have issues creating resources with AWS CLI, try using the env variables instead of the `aws configure` command for credentials. Make sure to include `AWS_REGION` or use the `--region` flag in every command.
   > * The same Transit Gateway can be used in multiple networks, but they must be shared by different RAM shares.

1. Export the transit gateway ID and ARN to your environment:
   ```sh
   export TRANSIT_GATEWAY_ID=$(jq -r '.TransitGateway.TransitGatewayId' tgw.json)
   export TRANSIT_GATEWAY_ARN=$(jq -r '.TransitGateway.TransitGatewayArn' tgw.json)
   ```
   {: data-test-step="block" }

## Create a resource share in AWS

Create a resource share to allow the AWS account associated with your {{site.konnect_short_name}} account to access the AWS Transit Gateway.

1. Fetch the information about the AWS account associated with your {{site.konnect_short_name}}:

   ```sh
   curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $KONNECT_TOKEN" -XGET https://global.api.konghq.com/v2/cloud-gateways/provider-accounts | jq
   ```

1. Export the value of the `provider_account_id` field to your environment:

   ```sh
   export CLOUD_AWS_ACCOUNT_ID=$(curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $KONNECT_TOKEN" -XGET https://global.api.konghq.com/v2/cloud-gateways/provider-accounts | jq -r '.data[0].provider_account_id')
   ```
   {: data-test-step="block" }

1. Use this command to create a resource share and save its output:

   ```sh
   aws ram create-resource-share --name transit-gateway-resource-share --resource-arns $TRANSIT_GATEWAY_ARN --principals $CLOUD_AWS_ACCOUNT_ID > resource-share.json
   ```
   {: data-test-step="block" }

1. Export the resource share ARN to your environment:

   ```sh
   export RESOURCE_SHARE_ARN=$(jq -r '.resourceShare.resourceShareArn' resource-share.json)
   ```
   {: data-test-step="block" }

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

1. Fetch the list of transit gateway VPC attachments:

   ```sh
   aws ec2 describe-transit-gateway-vpc-attachments
   ```

1. Accept the transit gateway attachment. The command finds the attachment for the transit gateway you created and accepts it:

   ```sh
   aws ec2 accept-transit-gateway-vpc-attachment --transit-gateway-attachment-id $(aws ec2 describe-transit-gateway-vpc-attachments | jq -r --arg tgw "$TRANSIT_GATEWAY_ID" '.TransitGatewayVpcAttachments[] | select(.TransitGatewayId==$tgw) | .TransitGatewayAttachmentId')
   ```
   {: data-test-step="block" data-test-retry-count="6" }

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectCloudGatewayTransitGateway
name: konnect-aws-transit-gateway-1
{% endvalidation %}
<!-- vale on -->
