---
title: "Dedicated Cloud Gateways network architecture"
content_type: reference
layout: reference
description: "Learn the architecture of Kong-managed Dedicated Cloud Gateways networks, how they communicate with your cloud infrastructure, and what you must decide before deploying a Dedicated Cloud Gateway."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: Dedicated Cloud Gateways private network architecture and security
    url: /dedicated-cloud-gateways/private-network/
  - text: Dedicated Cloud Gateways public network architecture and security
    url: /dedicated-cloud-gateways/public-network/
  - text: Multi-cloud Dedicated Cloud Gateway network architecture and security
    url: /dedicated-cloud-gateways/multi-cloud/
tags:
  - dedicated-cloud-gateways
---

In a Dedicated Cloud Gateway, Kong manages the gateway infrastructure (compute, Dedicated Cloud Gateway network, and data planes) for you in a single-tenant cloud environment dedicated to your organization (AWS, GCP, Azure).
A complete Dedicated Cloud Gateway deployment consists of this Kong-managed network infrastructure and the cloud infrastructure with the upstream services you manage.

The following diagram shows how traffic flows in a Dedicated Cloud Gateway:
<!--vale off-->
{% mermaid %}
flowchart LR
    A(API consumers) --> |inbound edge| B(Kong data planes)
    B --> |upstream path| C(Your services)
{% endmermaid %}
<!--vale on-->

The networking decisions you make govern both hops independently.

Before you deploy a Dedicated Cloud Gateway, you must make some choices to determine how to deploy it based on your network and upstream service configuration:
1. Decide which cloud provider or providers (AWS, Azure, GCP) you want to use based on where your upstream service cloud infrastructure is currently deployed.
1. Decide if you want a [public or private Dedicated Cloud Gateway](#public-and-private-network-connectivity) (or both) depending on if your upstream traffic is public or private.
1. For private Dedicated Cloud Gateways:
   * Decide how {{site.base_gateway}} will connect to your upstream services via private network peering (VPC/VNET), hub-and-spoke networking (Transit gateway, VWAN), or private endpoints (AWS resource endpoints).
   * Decide how to resolve hostnames, either via private DNS or outbound DNS resolver (when your hostnames live on a separate DNS server).
1. Decide if you need a [multi-cloud Dedicated Cloud Gateway](#multi-cloud-architecture) for high-availability.

## Kong-managed gateway infrastructure architecture

The Kong-managed gateway infrastructure consists of data plane nodes that run inside of a Kong-managed network peering (VPC or VNET depending on your provider).
The Kong-managed data plane nodes automatically scale with your throughput. 

The following diagram shows what the Kong-managed architecture looks like if you chose AWS as your provider:
<!--vale off-->
{% mermaid %}
flowchart LR
    subgraph kong_account["Kong-managed AWS infra"]
        subgraph kong_vpc["Kong-managed VPC"]
          dp1["<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data plane node"]
          dp2["<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data plane node"]
          dp3["<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data plane node"]
        end
    end

    style kong_account stroke-dasharray:3,rx:10,ry:10
{% endmermaid %}
<!--vale on-->

In a Dedicated Cloud Gateway, the Kong-managed infrastructure would communicate with your own cloud infrastructure that contains your databases, APIs, and other resources.
Your infrastructure can run on virtual machines (VMs), managed container platforms like ECS, Kubernetes managed pods, or a combination of multiple platforms.
If the services are backed VMs or managed container platforms, Kong mostly expects you to expose them via load balancer. 
If the services are in Kubernetes managed pods, they can either be exposed via a shared ingress or if only a small set of services need to be exposed, they can be directly exposed by a load balancer service. 

## Load balancing

{{site.konnect_short_name}} uses cross-availability zone load balancing to distribute traffic evenly across data plane nodes in all availability zones where your Dedicated Cloud Gateway is deployed. 
Load balancing happens at the connection level, not per request.
Multiple requests sent over the same TCP connection go to the same data plane node. 
Different connections distribute across nodes.

## Public and private network connectivity

Before you deploy a Dedicated Cloud Gateway, you'll need to determine if you should deploy a public or private gateway, or both.
Which you deploy depends on how API consumers are reaching your gateway and how you want data planes to reach your backend services:

* Use [public](/dedicated-cloud-gateways/public-network/) if:
  * You expose services to the internet with custom access control
  * Want minimal setup and are securing at the Kong layer
  * You're proxying your own infrastructure over the public internet
* Use [private](/dedicated-cloud-gateways/private-network/) if:
  * Your upstream services are on one or more private network (VPC or VNET)
  * You don't expose services to the public internet
  * Require network isolation or full edge control
  * Operate under regulated security requirements

Use both a public and private Dedicated Cloud Gateway if some of your traffic is public-facing and other traffic is private.

The following table describes which cloud providers and private networking configurations are supported:

{% feature_table %}
item_title: Feature
columns:
  - title: AWS
    key: aws
  - title: GCP
    key: gcp
  - title: Azure
    key: azure
features:
  - title: Public Dedicated Cloud Gateway
    aws: true
    gcp: true
    azure: true
  - title: Private network peering
    aws: true
    gcp: true
    azure: true
  - title: Private hub-and-spoke network
    aws: true
    gcp: false
    azure: true
  - title: Private endpoints
    aws: true
    gcp: false
    azure: false
{% endfeature_table %}


## Multi-cloud architecture

{% include sections/dcgw-multi-cloud-intro.md %}

For more information, see [Multi-cloud Dedicated Cloud Gateway network architecture](/dedicated-cloud-gateways/multi-cloud/).

## WAF

{% include /sections/dcgw-waf-intro.md %}

Kong strongly recommends configuring a WAF for public and private Dedicated Cloud Gateways. 
WAF configuration differs for [public](/dedicated-cloud-gateways/public-network/) and [private](/dedicated-cloud-gateways/private-network/) deployments.

## Dedicated Cloud Gateway network CIDR range

Before you create a Dedicated Cloud Gateway network, determine which CIDR range you want to use for your network.
A CIDR block defines the range of IP addresses available for your Dedicated Cloud Gateway. 
If you're configuring private network connectivity, this CIDR block **must not** overlap with CIDR blocks assigned in your own cloud service provider networks to prevent conflicts.
Keep in mind that your Dedicated Cloud Gateway network CIDR block must be large enough to cover the Kong infrastructure Kong will provision inside it, such as the data plane nodes, the DNS proxy, internal load balancers, and any other components Kong manages. 

Keep the following CIDR requirements in mind when you're deciding your network CIDR range:
* **Prefix length:** The CIDR block must have a prefix length between `/16` and `/23`. `/23` blocks are only supported for up to 3 availability zones.
* **Private IP Range:** The entire CIDR block must fall within one of these private IP ranges:
  * 10.0.0.0/8
  * 100.64.0.0/10
  * 172.16.0.0/12
  * 192.168.0.0/16
  * 198.18.0.0/15
  
  {:.info}
  > **Acceptable CIDR examples:**
  > * 10.4.0.0/16
  > * 100.68.0.0/20
  > * 172.20.0.0/22
  > * 192.168.128.0/18
  > * 198.18.0.0/16
* **No overlap with existing ranges:** Your CIDR block **must not** overlap with any IP ranges already in use by your organization. Overlapping ranges can prevent network peering from functioning correctly.
* **No overlap with reserved CIDR blocks:** Your CIDR block must not overlap with these reserved ranges:
  * 10.100.0.0/16
  * 172.17.0.0/16

## Configure a Dedicated Cloud Gateway network

You can configure a Dedicated Cloud Gateway network using the {{site.konnect_short_name}} UI, API, or Terraform.

{% navtabs "dcgw-network" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Network**.
1. Click **New Network**.
1. From the **Provider** dropdown menu, select the cloud provider you want to deploy your Dedicated Cloud Gateway in.
1. From the **Region** dropdown menu, select the region you want to configure the cluster in. 
1. In the **Network name** field, enter a unique display name for your network.
1. In the **CIDR for Dedicated Cloud** field, enter your CIDR block.

   {:.danger}
   > **Important:** Your CIDR block **must not** overlap with any IP ranges already in use by your organization. Overlapping ranges can prevent network peering from functioning correctly. The default range is `10.0.0.0/16`, but this can be edited.
1. Click **Save**.
{% endnavtab %}
{% navtab "API" %}
1. Send a `GET` request to the [`/cloud-gateways/provider-accounts` endpoint](/api/konnect/cloud-gateways/v2/#/operations/list-provider-accounts) to get all cloud provider IDs:
{% konnect_api_request %}
url: /v2/cloud-gateways/provider-accounts
method: GET
region: global
{% endkonnect_api_request %}
1. In the response, copy and export the ID for the cloud provider you want to use for your Dedicated Cloud Gateway network:
   ```sh
   export CLOUD_PROVIDER_ID='YOUR CLOUD PROVIDER ID'
   ```
1. Send a `POST` request to the [`/cloud-gateways/networks` endpoint](/api/konnect/cloud-gateways/v2/#/operations/create-network) to create your Dedicated Cloud Gateway network:
   {% konnect_api_request %}
   url: /v2/cloud-gateways/networks
   method: POST
   region: global
   body:
     name: "us-east-2 network"
     cloud_gateway_provider_account_id: "$CLOUD_PROVIDER_ID"
     region: "us-east-2"
     availability_zones:
       - "use2-az1"
       - "use2-az2"
       - "use2-az3"
     cidr_block: "10.4.0.0/16"
   {% endkonnect_api_request %}
{% endnavtab %}
{% navtab "Terraform" %}
[Create a Dedicated Cloud Gateway network](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/scenarios/cloud-gateways.tf):

<!--vale off-->
```hcl
echo '
data "konnect_cloud_gateway_provider_account_list" "my_cloudgatewayprovideraccountlist" {
  page_number = 1
  page_size   = 1
}

resource "konnect_cloud_gateway_network" "my_cloudgatewaynetwork" {
  name   = "Terraform Network"
  region = "eu-west-1"
  availability_zones = [
    "euw1-az1",
    "euw1-az2",
    "euw1-az3"
  ]

  cidr_block      = "10.4.0.0/16"

  cloud_gateway_provider_account_id = data.konnect_cloud_gateway_provider_account_list.my_cloudgatewayprovideraccountlist.data[0].id
}
' >> main.tf
```
<!--vale on-->

Apply changes:
```sh
terraform apply -auto-approve
```
{% endnavtab %}
{% endnavtabs %}

{:.warning}
> **Important:** It can take 30-40 minutes for your network to initialize. 
> You **must** wait for your network to display as `Ready` before you can configure private networking.