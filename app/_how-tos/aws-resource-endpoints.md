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
    - title: "AWS IAM permissions"
      content: |
        You need an AWS IAM user account with permissions to create AWS Resource Configuration Groups, Resource Gateways, and to use AWS Resource Access Manager (RAM).
      icon_url: /assets/icons/aws.svg

---

## Create Resource Configuration Group and Resource Gateway

AWS resource endpoints with dedicated cloud gateway enables secure, one-way connectivity from {{site.konnect_short_name}}’s managed infrastructure to your upstream services—without requiring VPC peering or Transit Gateway. 

AWS VPC endpoints, part of the AWS VPC Lattice offering, allow services in one AWS account to be securely shared with and accessed from another account via a single VPC dndpoint. This eliminates the need for:
* Multiple PrivateLinks
* Individual TLS workarounds for each service
* Complex two-way handshakes

To use AWS resource endpoints with dedicated cloud gateways, you must first create a resource configuration group and resource gateway in AWS.

1. In the AWS console, navigate to **AWS VPC Lattice**.
Log in to your AWS Console.
Navigate to AWS VPC Lattice.
Click Create Resource Configuration Group.
Specify a name (e.g., Kong-DCGW-Resources) and add each upstream service as a child resource.
Add Resource Configuration (resources) to this group. 	

## Share Resource Configuration Group with Kong
Navigate to AWS Resource Access Manager (RAM).
Click Share Resource.
Select the Resource Configuration Group created.
Share this configuration with Kong’s DCGW AWS Account ID.

## Information Collection and Sharing
Document each upstream service domain name and its Resource Configuration ID. Until DNS is automated by AWS, Kong will need to create a mapping of upstream domain names and Resource Configuration IDs.  

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


