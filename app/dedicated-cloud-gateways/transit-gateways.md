---
title: "AWS Transit Gateway Peering"
content_type: reference
layout: reference
description: |
  Connect {{site.konnect_short_name}} Dedicated Cloud Gateways to AWS Transit Gateway for private, secure connectivity.
products:
  - gateway
works_on:
  - konnect
api_specs:
  - konnect/control-planes-config

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Amazon VPC Transit Gateway documentation
    url: https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started.html
---

When you deploy Dedicated Cloud Gateways in {{site.konnect_short_name}}, you can use AWS Transit Gateway to establish private connectivity between your AWS-hosted services and the {{site.konnect_short_name}} platform. This creates a secure and scalable network path that avoids exposing internal APIs to the public internet.

<!--vale off -->
{% mermaid %}
flowchart LR

A(API or Service)
B(API or Service)
C(API or Service)
D(<img src="/assets/icons/third-party/aws-transit-gateway-attachment.svg" style="max-height:32px" class="no-image-expand"/>AWS \n Transit Gateway \n attachment)
E(<img src="/assets/icons/third-party/aws-transit-gateway.svg" style="max-height:32px" class="no-image-expand"/> AWS \n Transit Gateway)
F(<img src="/assets/icons/third-party/aws-transit-gateway-attachment.svg" style="max-height:32px" class="no-image-expand"/>AWS \n Transit Gateway \n attachment)
G(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect \n#40;fully-managed \ndata plane#41;)
H(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect \n#40;fully-managed \ndata plane#41;)
I(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect \n#40;fully-managed \ndata plane#41;)
J(Internet)

subgraph 1 [User AWS Cloud]
    subgraph 2 [Region]
        subgraph 3 [Virtual Private Cloud #40;VPC#41;]
        A
        B
        C
        end
        A & B & C <--> D
    end
   D<-->E
end

subgraph 4 [Kong AWS Cloud]
    subgraph 5 [Region]
        E<-->F
        F <--private API \n access--> G & H & I
        subgraph 6 [Virtual Private Cloud #40;VPC#41;]
        G
        H
        I
        end
    end
end

G & H & I <--public API \n access--> J


{% endmermaid %}
<!--vale on-->

## AWS Configuration for Transit Gateway Peering

This process includes three main steps: 

1. Create and Share the Transit Gateway in AWS

    * Navigate to **VPC > Transit Gateways** in the AWS Console.
    * Select **Create transit gateway**, provide a name, and create the gateway.
    * Save the **Transit Gateway ID**.
    * Open the **Resource Access Manager**, and select **Create Resource Share**.
    * Choose **Transit Gateways** as the resource type and select the newly created gateway.
    * Name the resource share and retain default managed permission settings.
    * Enable **Allow external accounts**, choose **AWS Account**, and enter the **AWS ID** from the {{site.konnect_short_name}} UI (**Gateway Manager > Networks**).
    * Create the resource share and save the resulting **RAM Share ARN**.

2. Accept the Transit Gateway Attachment in AWS

    * Go to **VPC > Transit Gateway Attachments** in the AWS Console.
    * Locate the incoming attachment request from the {{site.konnect_short_name}} AWS Account ID.
    * Accept the request to establish the connection.

    Each AWS VPC that needs to send or receive traffic must have its own Transit Gateway attachment.

## Konnect Configuration for Transit Gateway Peering

To finish setup in {{site.konnect_short_name}}:

* Go to **Gateway Manager > Networks**.
* Select your network and click **Attach Transit Gateway**.
* Provide the following information:
  * Transit Gateway Name
  * One or more CIDR blocks (must not overlap with your {{site.konnect_short_name}} network)
  * RAM Share ARN
  * Transit Gateway ID

## Accept Transit Gateway Attachment in AWS

In the AWS Console:

* Go to **VPC > Transit Gateway Attachments**
* Wait for an attachment request from the Konnect AWS Account ID
* Accept the request

Ensure that each AWS VPC requiring traffic forwarding has its own Transit Gateway attachment.

After the attachment is active, create a route in your AWS VPC to forward traffic to the {{site.konnect_short_name}} managed VPC through the Transit Gateway. This ensures proper traffic flow from {{site.konnect_short_name}} to your Services and back.

## DNS Mappings

Add IP addresses of DNS servers and the corresponding domains. Supported mapping types include:

{% table %}
columns:
  - title: Mapping Type
    key: type
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - type: 1-to-1 Mapping
    description: Each domain is mapped to a unique IP address.
    example: "`example.com` → `192.168.1.1`"
  - type: N-to-1 Mapping
    description: Multiple domains share the same IP address.
    example: "`example.com`, `example2.com` → `192.168.1.1`"
  - type: M-to-N Mapping
    description: Multiple domains are mapped to multiple IPs without strict one-to-one pairing.
    example: >-
      `example.com`, `example2.com` → `192.168.1.1`, `192.168.1.2`
      <br><br>
      `example3.com` → `192.168.1.1`
{% endtable %}

