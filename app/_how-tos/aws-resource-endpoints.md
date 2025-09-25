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
  q: placeholder
  a: placeholder
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

        Copy and save the resource configuration ID for each resource configuration. {{site.konnect_short_name}} will use these to create a mapping of upstream domain names and resource configuration IDs.  

      icon_url: /assets/icons/aws.svg

---


## Get your Account ID

You'll need your account ID for AWS in {{site.konnect_short_name}}. AWS uses this account ID to configure the connection between your resource share in AWS and {{site.konnect_short_name}}.

1. In the {{site.konnect_short_name}} sidebar, click [**Networks**](https://cloud.konghq.com/global/networks/).
1. Click the settings icon next to your network.
1. Click **Configure private networking**.
1. Copy and save the ID in the **AWS Account ID** field.

## Create Resource Configuration Group and Resource Gateway

AWS resource endpoints with dedicated cloud gateway enables secure, one-way connectivity from {{site.konnect_short_name}}’s managed infrastructure to your upstream services—without requiring VPC peering or Transit Gateway. 

AWS VPC endpoints, part of the AWS VPC Lattice offering, allow services in one AWS account to be securely shared with and accessed from another account via a single VPC endpoint. This eliminates the need for:
* Multiple PrivateLinks
* Individual TLS workarounds for each service
* Complex two-way handshakes

To use AWS resource endpoints with dedicated cloud gateways, you must first create a resource configuration group and resource gateway in AWS.

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
1. In the **AWS Account** field, enter `?`.
1. Click **Next**.
1. Click **Create resource share**.  

## Submit Resource Endpoints form
Login to your Konnect account, navigate to Gateway Manager and your Dedicated Cloud Gateway
Click on Networking
Click the kebab {icon} and select “Configure private networking”
Click on the Resource Endpoints tab
Provide a Name for your Resource Endpoint Configuration
Provide your 12-digit AWS account number 
Provide the RAM share ARN for the Resource Configuration Group you shared in Step 3 above. 
Submit Resource Endpoints form. 

## Kong’s automation will accept the RAM share and create VPC endpoints
It may take a few minutes for automation to accept the RAM share and create VPC endpoints. You can check the status of your Resource Endpoints in the table. 

## Map your Resource Configuration IDs to upstream domain names.
Note: Until AWS support Private Hosted Zones for Resource Endpoints, you will need to manually map your Resource Configuration IDs to upstream resources so Kong can route to them correctly. In the future, this should not be required and will be automatically propagated.  
Once your Resource Endpoints are ‘Ready’, you can begin mapping your Resource Configuration IDs to upstream domain names. 
Populate the form with Resource Configuration IDs and corresponding domain names.
Click Save to configure Resource Endpoints.
It may take a few minutes for automation to update our Private Hosted Zones / DNS settings before proper upstream routing to work. 


