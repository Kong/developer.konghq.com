---
title: Set up an AWS resource endpoint connection
description: 'placeholder'
content_type: how_to
permalink: /dedicated-cloud-gateways/aws-resource-endpoints/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I configure AWS resource endpoints with Dedicated Cloud Gateway?
  a: |
    AWS resource endpoints with Dedicated Cloud Gateway enables secure, one-way connectivity from {{site.konnect_short_name}}’s managed infrastructure to your upstream services without requiring VPC peering or Transit Gateway. First, configure a resource share in AWS and set your {{site.konnect_short_name}} AWS account ID as a principal on the resource share. Configure private networking for you Dedicated Cloud Gateway and select **Resource endpoint connection**. Enter your resource share ARN from AWS as well as your resource configuration ID and domain name. 
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: AWS VPC endpoint documentation
    url: https://docs.aws.amazon.com/vpc/latest/privatelink/use-resource-endpoint.html
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways
      icon_url: /assets/icons/kogo-white.svg
    - title: "AWS"
      content: |
        You need an AWS IAM user account with permissions to create AWS Resource Configuration Groups, Resource Gateways, and to use AWS Resource Access Manager (RAM).

        You also need:
        * A configured [VPC and subnet](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html#create-vpc-and-other-resources)
        * A [resource gateway](https://docs.aws.amazon.com/vpc-lattice/latest/ug/create-resource-gateway.html)
        * A [resource configuration group](https://docs.aws.amazon.com/vpc-lattice/latest/ug/create-resource-configuration.html)
          
          Copy and save the resource configuration ID and resource definition domain name for each resource configuration. {{site.konnect_short_name}} will use these to create a mapping of upstream domain names and resource configuration IDs.  
        
        Export your AWS resource configuration domain name:
        ```sh
        export RESOURCE_DOMAIN_NAME='http://YOUR-RESOURCE-DOMAIN-NAME/anything'
        ```
        We'll use this to connect to our Dedicated Cloud Gateway service.
      icon_url: /assets/icons/aws.svg
    - title: Required entities
      content: |
        For this tutorial, you'll need {{site.base_gateway}} entities, like Gateway Services and Routes, pre-configured. These entities are essential for {{site.base_gateway}} to function but installing them isn't the focus of this guide. Follow these steps to pre-configure them:

        1. In the {{site.konnect_short_name}} sidebar, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/).
        1. Click your Dedicated Cloud Gateway.
        1. In the API Gateway sidebar, click **Gateway Services**.
        1. Click **New gateway service**.
        1. In the **Full URL** field, enter your resource domain, appended with `/anything`. For example: `http://YOUR-RESOURCE-DOMAIN-NAME/anything`
        1. In the **Name** field, enter `example-service`.
        1. Click **Save**.
        1. Click the **Routes** tab.
        1. Click **New route**.
        1. In the **Name** field, enter `example-route`.
        1. In the **Path** field, enter `/anything`.
        1. Click **Save**.

        To learn more about entities, you can read our [entities documentation](/gateway/entities/).
      icon_url: /assets/icons/widgets.svg
faqs:
  - q: Which Availability Zones (AZs) does AWS resource endpoints support for Dedicated Cloud Gateway?
    a: |
      Dedicated Cloud Gateways support the following AWS regions and [Availability Zones (AZ)](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html):

      <!--vale off-->
      {% table %}
      columns:
        - title: Region
          key: region
        - title: Supported Availability Zones
          key: az
      rows:
        - region: "Ohio (`us-east-2`)"
          az: |
            * `use2-az1`
            * `use2-az2`
            * `use2-az3`
        - region: "Oregon (`us-west-2`)"
          az: |
            * `usw2-az1`
            * `usw2-az2`
            * `usw2-az3`
            * `usw2-az4`
        - region: "N. Virginia (`us-east-1`)"
          az: |
            * `use1-az1`
            * `use1-az2`
            * `use1-az4`
            * `use1-az5`
            * `use1-az6`
        - region: "N. California (`us-west-1`)"
          az: |
            * `usw1-az1`
            * `usw1-az3`
        - region: "Montreal (`ca-central-1`)"
          az: |
            * `cac1-az1`
            * `cac1-az2`
            * `cac1-az4`
        - region: "Frankfurt (`eu-central-1`)"
          az: |
            * `euc1-az1`
            * `euc1-az3`
        - region: "Ireland (`eu-west-1`)"
          az: |
            * `euw1-az1`
            * `euw1-az2`
            * `euw1-az3`
        - region: "London (`eu-west-2`)"
          az: |
            * `euw2-az1`
            * `euw2-az2`
            * `euw2-az3`
        - region: "Paris (`eu-west-3`)"
          az: |
            * `euw3-az1`
            * `euw3-az2`
            * `euw3-az3`
        - region: "Tokyo (`ap-northeast-1`)"
          az: |
            * `apne1-az4`
            * `apne1-az1`
            * `apne1-az2`
        - region: "Seoul (`ap-northeast-2`)"
          az: |
            * `apne2-az1`
            * `apne2-az3`
        - region: "Mumbai (`ap-south-1`)"
          az: |
            * `aps1-az1`
            * `aps1-az2`
            * `aps1-az3`
        - region: "Singapore (`ap-southeast-1`)"
          az: |
            * `apse1-az1`
            * `apse1-az2`
            * `apse1-az3`
        - region: "Sydney (`ap-southeast-2`)"
          az: |
            * `apse2-az1`
            * `apse2-az2`
            * `apse2-az3`
      {% endtable %}
      <!--vale on-->
---

## Copy and save your {{site.konnect_short_name}} Account ID

Before you can configure AWS, you'll need your account ID for AWS in {{site.konnect_short_name}}. AWS uses this account ID to configure the connection between your resource share in AWS and {{site.konnect_short_name}}.

1. In the {{site.konnect_short_name}} sidebar, click [**Networks**](https://cloud.konghq.com/global/networks/).
1. Click the settings icon next to your network.
1. Click **Configure private networking**.
1. Click **Resource endpoint connection**.
1. Copy and save the ID in the **Kong AWS Account ID** field.

## Create a resource share in AWS

AWS resource endpoints with Dedicated Cloud Gateway enables secure, one-way connectivity from {{site.konnect_short_name}}’s managed infrastructure to your upstream services without requiring VPC peering or Transit Gateway. 

AWS VPC endpoints, part of the AWS VPC Lattice offering, allow services in one AWS account to be securely shared with and accessed from another account via a single VPC endpoint. This eliminates the need for:
* Multiple PrivateLinks
* Individual TLS workarounds for each service
* Complex two-way handshakes

To use AWS resource endpoints with Dedicated Cloud Gateways, you must first create a resource share with your resource configuration group and resource gateway in AWS.

1. In the AWS console, navigate to [**RAM**](https://console.aws.amazon.com/ram/home).
1. Click **Create resource share**.
1. In the **Name** field, enter `Kong-DCGW-Resource-Share`.
1. From the **Resource type** dropdown menu, select "VPC Lattice Resource Configurations".
1. Select the ARN of your resource configuration.
1. In the Selected resources settings, select your resource IDs.
1. Click **Next**.
1. Click **Next**.
1. In the Principals settings, select **Allow sharing with anyone**.
1. From the **Select principal type** dropdown menu, select "AWS Account".
1. In the **AWS Account** field, enter your account ID from {{site.konnect_short_name}}.
1. Click **Next**.
1. Click **Create resource share**.  

## Configure the resource endpoint connection in {{site.konnect_short_name}}

1. In the {{site.konnect_short_name}} sidebar, click [**Networks**](https://cloud.konghq.com/global/networks/).
1. Click the settings icon next to your network.
1. Click **Configure private networking**.
1. Click **Resource endpoint connection**.
1. In the **Resource links configuration name** field, enter `AWS-Resource-Share`.
1. In the **AWS RAM share ARN** field, enter your ARN.
1. Click **Submit**. 

It may take a few minutes for {{site.konnect_short_name}}’s automation to accept the RAM share and create VPC endpoints. You can check the status of your resource endpoints in the table. 

## Map your resource configuration IDs to upstream domain names

Now you need to manually map your resource configuration IDs from AWS to {{site.konnect_short_name}} once your resource endpoint is marked as `Ready`.

1. In the {{site.konnect_short_name}} sidebar, click [**Networks**](https://cloud.konghq.com/global/networks/).
1. Click the settings icon next to your network.
1. Click **Configure private networking**.
1. Click **Resource endpoint connection**.
1. In the **Resource configuration ID** field, enter your enter your resource configuration ID from AWS.
1. In the **Domain name** field, enter your resource configuration domain name from AWS.
1. Click **Submit**.

It may take a few minutes for automation to update the private hosted zones and DNS settings before upstream routing will work. 

## Validate

You can validate that the resource endpoint connections in {{site.konnect_short_name}} are working correctly by navigating to your Gateway Service:

```sh
curl -i -X GET "http://$RESOURCE_DOMAIN_NAME/anything"
```
