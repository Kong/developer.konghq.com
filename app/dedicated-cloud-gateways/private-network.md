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

Use a private Dedicated Cloud Gateway when you:
- Deploy upstream services on one or more private networks (VPC or VNet)
- Don't expose services to the public internet
- Require network isolation or full edge control
- Operate under regulated security requirements

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

### Network peering

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

### Hub-and-spoke network

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

### Private endpoints

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

## WAF

{% include /sections/dcgw-waf-intro.md %}

{:.warning}
> Kong strongly recommends configuring a WAF for private Dedicated Cloud Gateways.

### AWS WAF

In a private deployment, your Application Load Balancer (ALB) is the internet-facing entry point. 
AWS WAF attaches directly to the ALB and inspects all inbound HTTP(S) traffic before it reaches your Dedicated Cloud Gateway.
Traffic flows from the ALB to the Dedicated Cloud Gateway's static private IP addresses over your private network connection (VPC peering or Transit Gateway).

To configure AWS WAF for a private Dedicated Cloud Gateway:

1. [Create an internet-facing ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-application-load-balancer.html) in your AWS account.
1. [Create an AWS WAF Web ACL](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-creating.html) and associate it with the ALB.
   Configure [AWS managed rule groups](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html) and any custom rules you need, such as IP blocklists or rate limiting.
1. [Create a target group](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-target-group.html) with the following settings:
   * **Target type:** IP
   * **Targets:** The static private IP addresses of your Dedicated Cloud Gateway data plane nodes. 
     You can find these by sending a GET request to the [`/cloud-gateways/configurations` endpoint](/api/konnect/cloud-gateways/v2/#/operations/list-configurations). 
1. Configure ALB listener rules based on host headers and path patterns to route traffic to the correct target group.
1. [Enable HTTPS](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html) on your ALB listener using AWS Certificate Manager (ACM).
1. Ensure your [VPC peering](/dedicated-cloud-gateways/aws-vpc-peering/) or [Transit Gateway](/dedicated-cloud-gateways/transit-gateways/) route tables are updated to direct ALB traffic to the Dedicated Cloud Gateway private IP addresses.
1. Validate connectivity by sending a test request to the ALB DNS name and confirming it routes through WAF, the ALB, and the Dedicated Cloud Gateway to your upstream API.

Optionally, enable [AWS Shield Advanced](https://docs.aws.amazon.com/waf/latest/developerguide/shield-chapter.html) on the ALB for DDoS mitigation.

### Azure WAF

In a private deployment, Azure Front Door Premium acts as the internet-facing entry point with a built-in WAF policy.
Traffic flows from Azure Front Door to an Internal Load Balancer (ILB) in your Azure VNet over Private Link, then reaches the Dedicated Cloud Gateway over VNet peering.

To configure Azure WAF for a private Dedicated Cloud Gateway:

1. [Deploy Azure Front Door Premium](https://learn.microsoft.com/en-us/azure/frontdoor/create-front-door-portal) with a custom domain for your APIs.
1. Configure a [WAF policy](https://learn.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-create-portal) on the Front Door profile.
   Include managed rulesets such as OWASP 3.2 and any custom rules for IP allow/deny, rate limiting, or bot control.
   Set the mode to **Prevention** for production or **Detection** when testing rules.
1. [Create an Internal Load Balancer](https://learn.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-internal-portal) in your Azure VNet.
   Add the static private IP addresses of your Dedicated Cloud Gateway data plane nodes as backend targets.
   You can find these by sending a GET request to the [`/cloud-gateways/configurations` endpoint](/api/konnect/cloud-gateways/v2/#/operations/list-configurations).
1. [Enable Private Link](https://learn.microsoft.com/en-us/azure/frontdoor/private-link) for the Front Door origin configuration.
   Azure Front Door creates a managed private endpoint that connects to the ILB over Microsoft's private backbone network.
1. Ensure your [VNet peering](/dedicated-cloud-gateways/azure-peering/) or [Virtual WAN](/dedicated-cloud-gateways/azure-virtual-wan/) connection is configured between your VNet and the {{site.konnect_short_name}}-managed VNet.
   Update your Network Security Group (NSG) rules and route tables to allow inbound traffic from the ILB subnet to the Dedicated Cloud Gateway private IP addresses.
1. Validate connectivity by making test API calls from Azure Front Door through to your upstream API and confirming end-to-end request flow.