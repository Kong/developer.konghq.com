---
title: "Dedicated Cloud Gateways private network architecture and security"
content_type: reference
layout: reference
description: "Learn about private Dedicated Cloud Gateway network architecture, connectivity options, and how to secure your private network."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Dedicated Cloud Gateways network architecture
    url: /dedicated-cloud-gateways/network-architecture/
  - text: Dedicated Cloud Gateways public network architecture and security
    url: /dedicated-cloud-gateways/public-network/
  - text: Multi-cloud Dedicated Cloud Gateway network architecture
    url: /dedicated-cloud-gateways/multi-cloud/
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Outbound DNS resolver
    url: /dedicated-cloud-gateways/outbound-dns-resolver/
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
tags:
  - dedicated-cloud-gateways
---


In private mode, Dedicated Cloud Gateway endpoints have private IP addresses only. 
There's no public listener. 
All inbound traffic must arrive through your own edge infrastructure over a private network connection. 
Your CDN, WAF, or Application Load Balancer terminates public traffic and handles TLS, then forwards requests to the {{site.base_gateway}} data plane using its private IP address. 
The data plane has no public listener and is unreachable from the internet directly.

Use a private Dedicated Cloud Gateway when:
- Your upstream services are on one or more private networks (VPC or VNet)
- You don't expose services to the public internet
- You require network isolation or full edge control
- You operate under regulated security requirements

{:.info}
> **Note:** The inbound path (your edge to the Dedicated Cloud Gateway) and the upstream path (the Dedicated Cloud Gateway to your backend services) are independent network hops and can use different connectivity methods. 
> For example, your edge may reach the Dedicated Cloud Gateway over a Transit Gateway while the Dedicated Cloud Gateway reaches upstream services over a separate VNet peering connection.

## Private connectivity options

When you want a private connection from your Dedicated Cloud Gateway to your managed cloud infrastructure, you can choose from three connectivity types depending on your use case:

{% table %}
columns:
  - title: Connectivity type
    key: type
  - title: Use when
    key: when
  - title: Supported clouds
    key: clouds
rows:
  - type: "[Network peering](#network-peering)"
    when: |
      * Your upstream services are in a single VPC or VNet
      * You want a direct, low-overhead connection without a transit hub
      * Your CIDR ranges don't overlap
    clouds: AWS, Azure, GCP
  - type: "[Hub-and-spoke network](#hub-and-spoke-network)"
    when: |
      * Your upstream services are spread across multiple VPCs or VNets, including across accounts
      * You want a scalable, centrally managed connectivity model
      * You already operate a hub-and-spoke network topology
    clouds: AWS, Azure
  - type: "[Private endpoints](#private-endpoints)"
    when: |
      * Your security model requires a defined network boundary
      * You want to avoid VPC-level peering while still connecting to one or many upstream services
      * Your upstreams sit behind ALBs or other load balancers that handle L7 routing
    clouds: AWS
{% endtable %}

Your team is responsible for the following components regardless of which connectivity type you use:

{% table %}
columns:
  - title: Component
    key: component
  - title: Your responsibility
    key: responsibility
rows:
  - component: Public entry point
    responsibility: CDN, WAF, or ALB in your cloud account
  - component: TLS termination
    responsibility: At your edge (with re-origination to {{site.base_gateway}}) or L4 passthrough directly to {{site.base_gateway}}
  - component: Private connectivity
    responsibility: VPC peering, Transit Gateway, VNet peering, or Virtual Hub to the {{site.konnect_short_name}}-managed network
  - component: DNS
    responsibility: CNAME from your hostname to your edge, not directly to {{site.base_gateway}}
  - component: Firewall rules
    responsibility: Allow your edge to reach Dedicated Cloud Gateway private IPs on the gateway port
{% endtable %}

{:.info}
> **Dedicated Cloud Gateway private IPs:**
> Dedicated Cloud Gateway data plane private IP addresses are static. 
> You can retrieve them from the {{site.konnect_short_name}} UI or API to use as targets in your ALB target group or firewall rules.

## Network peering

Network peering establishes a direct, private connection between the {{site.konnect_short_name}}-managed network and a single VPC or VNet in your cloud account. 
Traffic routes over the cloud provider's internal network without traversing the public internet. 
{{site.konnect_short_name}} initiates the peering request from the managed network. 
You accept it in your cloud account and update your route tables to route traffic across the peering connection.

The following diagram shows an example of a VPC peering network:
<!--vale off -->
{% mermaid %}
flowchart LR

A(API or Service)
B(API or Service)
C(API or Service)
E(<img src="/assets/icons/aws.svg" style="max-height:32px" class="no-image-expand"/> AWS VPC peering)
G(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
H(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
I(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
J(Internet)

subgraph 1 [User AWS Cloud]
    subgraph 2 [Region]
        subgraph 3 [Virtual Private Cloud #40;VPC#41;]
        A
        B
        C
        end
        A & B & C <--> E
    end
end

subgraph 4 [Kong AWS Cloud]
    subgraph 5 [Region]
        E <--private API access--> G & H & I
        subgraph 6 [Virtual Private Cloud #40;VPC#41;]
        G
        H
        I
        end
    end
end

G & H & I <--public API access--> J
{% endmermaid %}
<!--vale on-->

To set up network peering, use the following tutorials:
* [Set up an AWS VPC peering connection](/dedicated-cloud-gateways/aws-vpc-peering/)
* [Set up a GCP VPC peering connection](/dedicated-cloud-gateways/gcp-vpc-peering/)
* [Configure an Azure Dedicated Cloud Gateway with VNET peering](/dedicated-cloud-gateways/azure-peering/)

After you've configured network peering in {{site.konnect_short_name}}, do the following:
- Update your route tables to route the {{site.konnect_short_name}}-managed network CIDR via the peering connection.
- Configure security groups or network security group rules to allow inbound traffic from the {{site.base_gateway}} data plane private IPs on your service ports.
- Configure private DNS so {{site.base_gateway}} can resolve your service hostnames to private IPs.

## Hub-and-spoke network

A hub-and-spoke network uses a centrally managed hub that all networks connect to once. 
The hub handles routing between all attached networks, so a single connection from the {{site.konnect_short_name}}-managed network can reach services across multiple VPCs or VNets without requiring individual peering connections to each one. 
Route tables on the hub let you define precisely which networks can communicate with each other, limiting {{site.base_gateway}}'s reachability to specific networks.

The following diagram shows an example of a transit gateway hub-and-spoke network:
{% include diagrams/dcgw-tgw.md %}

To set up a hub-and-spoke network, use the following tutorials:
* [AWS Transit Gateway peering](/dedicated-cloud-gateways/transit-gateways/)
* [Configure an Azure Dedicated Cloud Gateway with virtual WAN](/dedicated-cloud-gateways/azure-virtual-wan/)

After you've configured the hub-and-spoke network in {{site.konnect_short_name}}, do the following:
- Update your route tables to route traffic between the {{site.konnect_short_name}}-managed network CIDR and your spoke networks.
- Configure security groups or network security group rules to allow inbound traffic from {{site.base_gateway}} data plane private IPs on your service ports.
- Configure private DNS so {{site.base_gateway}} can resolve your service hostnames to private IPs.

## Private endpoints

Private endpoints provide one-way private connectivity from the {{site.konnect_short_name}}-managed network to resources in your AWS account using AWS VPC Lattice resource configurations. 
There's no VPC-level network access, only what you explicitly expose via a resource configuration is reachable from the {{site.konnect_short_name}}-managed network. 
A resource configuration can be a single endpoint or a group configuration with multiple child resource configurations, each pointing to a different service endpoint.

The following diagram shows an example of an AWS resource endpoint connection:
<!--vale off -->
{% mermaid %}
flowchart LR

A(API or Service)
B(API or Service)
C(API or Service)
E(<img src="/assets/icons/aws.svg" style="max-height:32px" class="no-image-expand"/> AWS Resource Endpoint)
G(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
H(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
I(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
J(Internet)

subgraph 1 [User AWS Cloud]
    subgraph 2 [Region]
        subgraph 3 [Virtual Private Cloud #40;VPC#41;]
        A
        B
        C
        end
        A & B & C --- E
    end
end

subgraph 4 [Kong AWS Cloud]
    subgraph 5 [Region]
        E --private API access--> G & H & I
        subgraph 6 [Virtual Private Cloud #40;VPC#41;]
        G
        H
        I
        end
    end
end

G & H & I <--public API access--> J
{% endmermaid %}
<!--vale on-->

To set up private endpoints, use the [Set up an AWS resource endpoint connection](/dedicated-cloud-gateways/aws-resource-endpoints/) tutorial.

After you've set up the AWS resource endpoint in {{site.konnect_short_name}}, ensure your service is reachable via the configured domain name within the shared resource.

## DNS for private upstream services

Regardless of the connectivity type you use, {{site.base_gateway}} must be able to resolve your upstream service hostnames to private IP addresses. 
Using private IPs directly in service configuration is possible but not recommended for services that require TLS, since certificates are typically issued to hostnames, not IPs.

There are two DNS options for private Dedicated Cloud Gateways depending on where your authoritative DNS records live:
- **Private hosted zone:** Use this when your DNS records live in your cloud provider's managed DNS service. 
  DNS traffic travels over the cloud provider's backbone network. 
  See [Private hosted zones](/dedicated-cloud-gateways/private-hosted-zones/).
- **Outbound DNS resolver:** Use this when your DNS records live on an on-premises or self-managed DNS server outside your cloud provider. 
  DNS traffic travels through your VPC peering or Transit Gateway connection. 
  See [Outbound DNS resolver](/dedicated-cloud-gateways/outbound-dns-resolver/).