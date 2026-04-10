---
title: "Dedicated Cloud Gateways network architecture"
content_type: reference
layout: reference
description: "Dedicated Cloud Gateways are Data Plane nodes that are fully managed by Kong in {{site.konnect_short_name}}."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect

faqs:
  - q: 
    a: 

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: Serverless Gateways
    url: /serverless-gateways/
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

In a Dedicated Cloud Gateway, Kong manages your data plane nodes for you in the cloud provider of your choice (AWS, GCP, Azure).
A complete Dedicated Cloud Gateway deployment consists of this Kong-managed network infrastructure and the cloud infrastructure you manage.
The Kong-managed infrastructure is automatically created in AWS, GCP, or Azure. 
It consists of data plane nodes that run on a Kubernetes cluster inside of a Kong-managed network peering (VPC or VNET depending on your provider).
The Kong-managed data plane nodes automatically scale with your throughput. 

The following diagram shows what the Kong-managed architecture looks like if you chose AWS as your provider:

{% mermaid %}
flowchart LR
    subgraph kong_account["Kong-managed AWS infra"]
        subgraph kong_vpc["Kong-managed VPC"]
            subgraph k8s["k8s cluster"]
                dp1["<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data plane node"]
                dp2["<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data plane node"]
                dp3["<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data plane node"]
            end
        end
    end

    style kong_account stroke-dasharray:3,rx:10,ry:10
{% endmermaid %}

In a Dedicated Cloud Gateway, the Kong-managed infrastructure would communicate with your own cloud infrastructure that contains your databases, APIs, and other resources.
Your infrastructure can run on virtual machines (VMs), managed container platforms like ECS, Kubernetes managed pods, or a combination of multiple platforms.
If the services are backed VMs or managed container platforms, Kong mostly expects you to expose them via load balancer. 
If the services are in Kubernetes managed pods, they can either be exposed via a shared ingress or if only a small set of services need to be exposed, they can be directly exposed by a load balancer service.

## Configure a Dedicated Cloud Gateway network

You can configure a Dedicated Cloud Gateway network using the {{site.konnect_short_name}} UI, API, or Terraform.

Before you create a Dedicated Cloud Gateway network, determine which CIDR range you want to use for your network.
A CIDR block defines the range of IP addresses available for your Dedicated Cloud Gateway. If you're configuring private network connectivity, this CIDR block **must not** overlap with CIDR blocks assigned in your own cloud service provider networks to prevent conflicts.
Keep in mind that your Dedicated Cloud Gateway network CIDR block must be large enough to cover the Kong infrastructure Kong will provision inside it, such as the data plane nodes, the DNS proxy, internal load balancers, and any other components Kong manages. 

Keep the following CIDR requirements in mind when you're deciding your network CIDR range:
* **Prefix length:** The CIDR block must have a prefix length between `/16` and `/23`. `/23` blocks are only supported up to 3 availability zones.
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
1. Send a `GET` request to the `/cloud-gateways/provider-accounts` endpoint to get all cloud provider IDs:
{% konnect_api_request %}
url: /v2/cloud-gateways/provider-accounts
method: GET
headers:
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}
1. In the response, copy and export the ID for the cloud provider you want to use for your Dedicated Cloud Gateway network:
   ```sh
   export CLOUD_PROVIDER_ID='YOUR CLOUD PROVIDER ID'
   ```
1. Send a `POST` request to the `` endpoint to create your Dedicated Cloud Gateway network:
{% konnect_api_request %}
url: /v2/cloud-gateways/networks
method: POST
headers:
  - 'Accept: application/json, application/problem+json'
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
{% endnavtab %}
{% endnavtabs %}

{:.warning}
> **Important:** It can take 30-40 minutes for your network to initialize. 
> You **must** wait for your network to display as `Ready` before you can configure private networking. 

## Public vs private

You can choose to have a private or public Dedicated Cloud Gateway, or use both public and private.
* **Public:** Use public if all your proxy traffic is public.
* **Private:** Use private if all your proxy traffic is private.
* **Public and private:** Use both a public and private Dedicated Cloud Gateway if some of your traffic is public-facing and other traffic is private.

The following table describes which cloud providers and private networking configurations are supported:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: AWS
    key: aws
  - title: GCP
    key: gcp
  - title: Azure
    key: azure
rows:
  - feature: Public Dedicated Cloud Gateway
    aws: "Y"
    gcp: "Y"
    azure: "Y"
  - feature: Private network peering
    aws: "Yes (VPC)"
    gcp: "Yes (VPC)"
    azure: "Yes (VNET)"
  - feature: Private hub-and-spoke network
    aws: "Yes (TGW)"
    gcp: "No"
    azure: "Yes (VWAN)"
  - feature: Private endpoints
    aws: "Yes (resource endpoints)"
    gcp: "No"
    azure: "No"
{% endtable %}

## Public architecture and connectivity

When a Dedicated Cloud Gateway (DCGW) proxies traffic to upstream services over
the public internet, you need security controls across the full request path —
validating who can call your APIs, and ensuring your upstream services can trust
that requests genuinely originate from Kong.

This page covers controls at both layers and how to combine them for defense in
depth.

{:.note}
> This page covers security controls for public internet upstream connectivity.
> Some controls (mTLS Auth, OIDC) validate inbound API consumers before
> requests reach your upstream. Others (upstream mTLS, shared secrets) authenticate
> Kong to your upstream service. For securing the inbound entry point itself,
> see [WAF and CDN integration with Dedicated Cloud Gateways](/).

Public internet connectivity between Kong and your upstream services is
appropriate when:

- Your upstream services are already internet-facing (for example, SaaS
  backends or services shared across business units without private networking)
- Traffic volume doesn't justify the operational overhead of private network
  peering
- Your security model relies on application-layer controls rather than
  network-layer isolation

For workloads with stricter isolation requirements, consider
[private upstream connectivity](#private-architecture-and-connectivity)
instead.

Kong data planes egress to your upstream services over the public internet.
Konnect exposes **static egress IP addresses** for each DCGW network in the
Konnect UI. You allowlist these IPs at your firewall or load balancer so that
only Kong proxy traffic can reach your backends.

IP allowlisting alone is a network-layer control — it restricts *who* can
send traffic, not *what* the traffic contains or *who* sent it at the
application layer. For production workloads, combine it with one or more of
the controls below.

### Securing public

These controls are complementary. A robust public internet configuration
typically combines multiple layers:

| Layer | Control | Protects against |
|---|---|---|
| Network | Egress IP allowlisting | Unauthorized source IPs |
| Transport | Upstream mTLS | Impersonation, MITM |
| Application | Shared secret header | Bypassed IP rules |
| Application | OIDC / JWT validation | Unauthorized callers |

A minimal production configuration for sensitive services: **egress IP
allowlisting + upstream mTLS**.

A configuration for services that cannot do mTLS: **egress IP allowlisting +
shared secret + OIDC**.

Customer requirements:
| Task | Your responsibility |
|---|---|
| Retrieve egress IPs | Konnect UI → your DCGW → **Connect** → Public Egress IPs |
| Allowlist egress IPs | Cloud security groups, firewall rules, or load balancer ACLs |
| Issue TLS certificates for mTLS | Provision a CA and issue certificates to Kong and your upstream services |
| Store shared secrets | Use Konnect vault references or your secrets manager |
| Configure identity provider for OIDC | Set up an IdP and issue credentials for Kong's OIDC plugin |

#### Egress IP allowlisting

Konnect exposes the static egress IP addresses for your DCGW network in the
Konnect UI. Configure your upstream firewall,
security group, or load balancer to accept inbound connections from these IPs
only.

This ensures that even if a service is publicly accessible, only your Kong data
planes can call it.

{:.note}
> Egress IPs are scoped per DCGW network and per region. If you operate
> multiple DCGW networks, allowlist the egress IPs from each relevant network.

**Steps:**

1. In Konnect, navigate to your DCGW and click **Connect**. The egress IP
   addresses are listed under **Public Egress IPs**.
2. In your cloud provider console, add inbound rules to your upstream service's
   security group or firewall to allow traffic from those IP ranges on the
   relevant port (typically 443 or 80).
3. Restrict inbound traffic on that port to the allowlisted IPs, in addition
   to any other legitimately permitted sources.


#### Mutual TLS (mTLS)

Mutual TLS authenticates both the Kong data plane and your upstream service
cryptographically. The upstream rejects any connection that doesn't present a
valid certificate, regardless of source IP. This provides a strong identity
guarantee even if an IP allowlist is bypassed or shared with another system.

Kong supports two mTLS modes for upstream connections:

##### Upstream mTLS

Kong presents a client certificate to your upstream service when establishing
the connection. Configure this on the Kong Service object by referencing a
certificate stored in Konnect via the `client_certificate` field.

Example service configuration using decK:

```yaml
services:
  - name: my-service
    url: https://api.internal.example.com
    client_certificate:
      id: <cert-uuid>
    tls_verify: true
    ca_certificates:
      - <ca-cert-uuid>
```

Your upstream verifies Kong's client certificate against a known CA before
accepting the connection.

##### Inbound mTLS with the mTLS Auth plugin

The [mTLS Auth plugin](https://developer.konghq.com/plugins/mtls-auth/)
validates client certificates presented *to* Kong from downstream API
consumers. Use this when your consumers must also authenticate with
certificates, creating end-to-end mutual authentication.

For services handling sensitive data, combine upstream mTLS with egress IP
allowlisting for defense in depth.



#### Shared secrets with the Request Transformer plugin

If your upstream service cannot terminate mTLS but you need a lightweight way
to verify that requests originate from Kong, inject a shared secret header
using the [Request Transformer plugin](https://developer.konghq.com/plugins/request-transformer/).

Example plugin configuration:

```yaml
plugins:
  - name: request-transformer
    config:
      add:
        headers:
          - "x-kong-origin-verify:{vault://env/KONG_SHARED_SECRET}"
```

{:.note}
> Replace `env/KONG_SHARED_SECRET` with the path matching your configured
> vault backend (`hcv`, `aws`, `gcp`, or `env`). See the
> [Secrets management documentation](https://developer.konghq.com/gateway/secrets-management/)
> for vault configuration options.

Your upstream service validates the presence and value of this header before
processing the request. If the header is absent or incorrect, the upstream
rejects the request.

**Security practices:**

- Store the secret as a Konnect vault reference, not as a plaintext value
- Rotate the secret on a regular schedule
- Combine with egress IP allowlisting so the header alone is not the only
  control


#### Token-based authentication with OpenID Connect

For APIs where caller identity matters beyond network origin, use the
[OpenID Connect plugin](https://developer.konghq.com/plugins/openid-connect/)
to validate JWTs or opaque tokens before forwarding requests upstream.

Kong validates the token at the gateway and can forward claims to your upstream
as headers, so your backend receives a verified identity without needing to
perform its own token validation.

This is particularly useful when:

- Upstream services are shared across multiple calling systems
- You want Kong to act as the centralized token validation and enforcement point
- You need fine-grained authorization based on token claims (scopes, roles,
  tenant ID)

## Private architecture and connectivity

When you want a private connection from your Dedicated Cloud Gateway to your managed cloud infrastructure, you can choose different bridging options depending on your use case:

Private network peering: 
Private hub-and-spoke network:
Private endpoints:

### Private network peering

### Private hub-and-spoke network

### Private endpoints

AWS resource endpoints

### Securing private



## Multi-cloud architecture

blah

use case about when certain ones are recommended

### Single Global Hostname (Geo‑Proximity DNS)

### Cloud‑Specific Hostnames (Recommended Default)

### Single Hostname + L7 Edge

