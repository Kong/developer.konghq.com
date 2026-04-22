---
title: "Dedicated Cloud Gateways public network architecture and security"
content_type: reference
layout: reference
description: "Learn about the public Dedicated Cloud Gateway network architecture and how to secure your public network."

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
  - text: Dedicated Cloud Gateways private network architecture and security
    url: /dedicated-cloud-gateways/private-network/
  - text: Multi-cloud Dedicated Cloud Gateway network architecture and security
    url: /dedicated-cloud-gateways/multi-cloud/
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
tags:
  - dedicated-cloud-gateways
---

Public Dedicated Cloud Gateways should be used when you are proxying your own infrastructure over public internet. 
Use a public deployment when:
- Your upstream services are already internet-facing (for example, SaaS
  backends or services shared across business units without private networking)
- Traffic volume doesn't justify the operational overhead of private network
  peering
- Your security model relies on application-layer controls rather than
  network-layer isolation

## Public architecture and connectivity

Public Dedicated Cloud Gateway endpoints are exposed via a Kong-managed Network Load Balancer (NLB)
with a public fully-qualified domain name (FQDN) and static public IP addresses.

Kong data planes egress to your upstream services over the public internet.
{{site.konnect_short_name}} exposes **static egress IP addresses** for each public Dedicated Cloud Gateway network. 
You must allowlist these IPs at your firewall or load balancer so that only Kong proxy traffic can reach your backends.

The following diagram shows how the architecture of a public Dedicated Cloud Gateway:
<!--vale off-->
{% mermaid %}
flowchart LR
    subgraph kong_account["Cloud provider"]
      nlb["NLB"]
        subgraph kong_vpc["Kong-managed VPC"]
            subgraph k8s["k8s cluster"]
                dp1["Data plane node"]
                dp2["Data plane node"]
                dp3["Data plane node"]
            end
            nlb --> dp1
            nlb --> dp2
            nlb --> dp3
        end
    end

    subgraph customer_infra["Customer infra"]
        lb["Load balancer"]
        vm1["VM"]
        vm2["VM"]
        vm3["VM"]
        lb -.-> vm1
        lb -.-> vm2
        lb -.-> vm3
    end

    dp1 --proxy--> lb
    dp2 --proxy--> lb
    dp3 --proxy--> lb

    style kong_account stroke-dasharray:3,rx:10,ry:10
{% endmermaid %}
<!--vale on-->

## Security controls

When a Dedicated Cloud Gateway proxies traffic to upstream services over the public internet, you need security controls across the full request path.
These validate who can call your APIs, and ensure your upstream services can trust that requests genuinely originate from Kong.
 
There are multiple security controls you can use to protect public Dedicated Cloud Gateways:
* Allow Kong proxy traffic by allowlisting egress IPs
* Validate inbound API consumers before requests reach your upstream (mTLS Auth, OIDC)
* Authenticate Kong to your upstream service (upstream mTLS, shared secrets)
* Secure the inbound entry point itself (CDN/WAF)

These security controls protect against the following:

{% table %}
columns:
  - title: Layer
    key: layer
  - title: Control
    key: control
  - title: Protects against
    key: protects
rows:
  - layer: Network
    control: Egress IP allowlisting
    protects: Unauthorized source IPs
  - layer: Transport
    control: Upstream mTLS
    protects: Impersonation, man-in-the-middle (MITM)
  - layer: Application
    control: Shared secret header
    protects: Bypassed IP rules
  - layer: Application
    control: OIDC/JWT validation
    protects: Unauthorized callers
{% endtable %}

Public Dedicated Cloud Gateway security controls are complementary.
A robust public internet configuration typically combines multiple layers:
* **A minimal production configuration for sensitive services:** Egress IP
allowlisting with upstream mTLS
* **A configuration for services that cannot do mTLS:** Egress IP allowlisting with
shared secret and OIDC

{:.warning}
> **Note:** We strongly recommend combining IP allowlisting with additional security controls in production.

For workloads with stricter isolation requirements, consider
[private upstream connectivity](/dedicated-cloud-gateways/private-network/)
instead.

### When to configure security controls

Public Dedicated Cloud Gateways are subjected to scanners when they are created, like any other publicly-exposed network.
We recommend creating and securing your public Dedicated Cloud Gateway in the following order:
1. *Before* creating Gateway Services and Routes, create the Dedicated Cloud Gateway network and control plane in {{site.konnect_short_name}}.
   The network will be scanned, but since there aren't any Routes, scanners get 404s or connection resets. 
2. Configure your CDN/WAF in front of the Kong NLB before you configure any Routes or Services. 
3. Allowlist the Dedicated Cloud Gateway network egress IPs.
4. Configure the IP Restriction plugin globally (allowlisting your CDN's egress IPs) so that even if someone hits the Kong NLB directly, they get rejected before any Route matching happens.
5. Configure your Routes and Services pointing to real upstreams.

### WAF

{% include /sections/dcgw-waf-intro.md %}

Kong strongly recommends configuring a WAF for public Dedicated Cloud Gateways. 
WAF configuration differs for public deployments.

Public Dedicated Cloud Gateways are exposed via a Kong-managed NLB with a public FQDN.
Most WAF services can't attach directly to a network-layer load balancer (NLB) because NLBs operate at Layer 4 and don't terminate HTTP. 
WAF inspection requires HTTP visibility, which means the WAF must sit at an HTTP-aware layer, like a CDN distribution, an Application Load Balancer, or a cloud edge service.

Additionally, because the Kong-managed NLB exposes a DNS hostname instead of an IP address, you can't chain another public load balancer in front of it (most ALB and cloud LB target groups don't support DNS-based targets).
Instead, you must use a CDN because it natively supports DNS-based origins and can attach WAF policies at the distribution level.

Examples of CDN or edge services that support this pattern:
- Amazon CloudFront with AWS WAF
- Azure Front Door with Azure WAF
- Cloudflare (WAF built in)
- Fastly with Next-Gen WAF

The following diagram shows how traffic flows through a public Dedicated Cloud Gateway with an AWS WAF:
<!--vale off -->
{% mermaid %}
sequenceDiagram
    Client->>+CloudFront/WAF: Sends request, TLS terminated
    CloudFront/WAF->>CloudFront/WAF: WAF evaluates

    alt WAF blocks request
        CloudFront/WAF-->>Client: 403 Forbidden
    else WAF passes request
        CloudFront/WAF->>CloudFront/WAF: CloudFront injects origin header
        CloudFront/WAF->>Kong NLB: Forwards request with origin header
        Kong NLB->>Kong DP node: Forwards request
        Kong DP node->>Kong DP node: Validates header

        alt Header missing or invalid
            Kong DP node-->>Client: 403 Forbidden
        else Header valid
            Kong DP node->>Kong DP node: Matches route
            Kong DP node->>Your upstream in AWS: Applies plugins, proxies request
            Your upstream in AWS-->>Kong DP node: Response
            Kong DP node-->>Kong NLB: Response
            Kong NLB-->>CloudFront/WAF: Response
            CloudFront/WAF-->>Client: Response
        end
    end
{% endmermaid %}
<!--vale on -->

In this model:
* CloudFront acts as the public edge entry point.
* AWS WAF is attached to the CloudFront distribution.
* The CloudFront origin is the Dedicated Cloud Gateway public DNS edge (public FQDN).
* The Kong-managed NLB receives traffic from CloudFront and forwards it to the gateway data planes.

This is the standard AWS-native pattern for protecting publicly accessible services behind an NLB.

The sections in this guide describe how to configure a WAF in AWS, but they can be adapted for Azure and GCP.

### Configure AWS WAF

When a Dedicated Cloud Gateway is deployed in public mode, it exposes a public FQDN backed by a Kong-managed Network Load Balancer. 
Without additional controls, clients could attempt to access this public endpoint directly and bypass CloudFront and AWS WAF protections.

To ensure all traffic passes through CloudFront, configure origin validation between CloudFront and Kong:
1. Configure CloudFront to inject a [custom origin header](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/add-origin-custom-headers.html). For example: `X-Origin-Verify: <shared-secret-value>`.
1. Configure your Dedicated Cloud Gateway to require the header. You can do this in two different ways:
   * Route-level header matching. For example:
     
     ```yaml
     routes:
      - name: my-route
        paths:
          - /anything
        headers:
          x-origin-verify:
            - your-secret-value
     ```
   * Use a plugin, like [Pre-Function](/plugins/pre-function/) or [Request Termination](/plugins/request-termination/)
1. Reject requests that don't include the expected header value.
1. Store the shared header value securely, like in a [Vault](/gateway/entities/vault/), and rotate the shared secret periodically.
1. If your CDN publishes static egress IP ranges, configure the [IP Restriction](/plugins/ip-restriction/examples/allow/) plugin globally (allowlisting your CDN's egress IPs). 
   Requests arriving from IPs outside the CDN's published ranges are rejected at the Kong layer before any route matching occurs. 
   Some CDNs that publish static egress IP ranges include CloudFront, Cloudflare, Azure Front Door, and Fastly.
1. Combine origin validation with [AWS WAF managed rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html) and [rate limiting](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based-request-limiting.html) for layered protection.

### Egress IP allowlisting

{{site.konnect_short_name}} exposes the static egress IP addresses for your Dedicated Cloud Gateway network in the {{site.konnect_short_name}} UI. 
You must configure your upstream firewall, security group, or load balancer to accept inbound connections from these IPs only.
This ensures that even if a Service is publicly accessible, only your Kong data
planes can call it.

{:.info}
> Egress IPs are scoped per Dedicated Cloud Gateway network and per region. 
> If you use multiple Dedicated Cloud Gateway networks, allowlist the egress IPs from each relevant network.

To allowlist the egress IPs, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click your Dedicated Cloud Gateway.
1. Click **Connect**.
1. Copy and save the IPs listed in **Public Egress IPs**.
2. In your cloud provider console, add inbound rules to your upstream service's
   security group or firewall to allow traffic from those IP ranges on the
   relevant port (typically 443 or 80).
3. Restrict inbound traffic on that port to the allowlisted IPs, in addition
   to any other legitimately permitted sources.

### Mutual TLS (mTLS)

Mutual TLS authenticates both the Kong data plane and your upstream service cryptographically. 
The upstream rejects any connection that doesn't present a valid certificate, regardless of source IP. 
This provides a strong identity guarantee even if an IP allowlist is bypassed or shared with another system.

Kong supports two mTLS modes for upstream connections: upstream mTLS and inbound mTLS.

#### Upstream mTLS

Kong presents a client certificate to your upstream service when establishing
the connection. 
Configure this on the Kong Service object by referencing a
certificate stored in {{site.konnect_short_name}} via the `client_certificate` field.

The following is an example Service configuration using decK:

{% entity_example %}
type: service
data:
  name: my-service
  url: https://api.internal.example.com
  client_certificate:
    id: $CERT_ID
  tls_verify: true
  ca_certificates:
    - $CA_CERT_ID
formats:
  - deck
{% endentity_example %}

In this example, your upstream verifies Kong's client certificate against a known CA before accepting the connection.

#### Inbound mTLS with the mTLS Auth plugin

The [mTLS Auth plugin](/plugins/mtls-auth/) validates client certificates presented *to* Kong from downstream API consumers. 
Use this when your consumers must also authenticate with certificates, creating end-to-end mutual authentication.
For Services handling sensitive data, combine upstream mTLS with egress IP allowlisting for in-depth defense.

Example plugin configuration:

{% entity_examples %}
entities:
  plugins:
    - name: mtls-auth
      service: my-service
      config:
        ca_certificates:
          - $CA_CERT_ID
formats:
  - deck
{% endentity_examples %}

### Shared secrets with the Request Transformer plugin

If your upstream service cannot terminate mTLS but you need a lightweight way
to verify that requests originate from Kong, inject a shared secret header
using the [Request Transformer plugin](/plugins/request-transformer/).

Example plugin configuration:

{% entity_examples %}
entities:
  plugins:
    - name: request-transformer
      config:
        add:
          headers:
            - "x-kong-origin-verify:{vault://env/KONG_SHARED_SECRET}"
formats:
  - deck
{% endentity_examples %}

{:.info}
> Replace `env/KONG_SHARED_SECRET` with the path matching your configured
> vault backend (`hcv`, `aws`, `gcp`, or `env`). See the
> [Secrets management documentation](/gateway/secrets-management/)
> for vault configuration options.

Your upstream service validates the presence and value of this header before
processing the request. If the header is absent or incorrect, the upstream
rejects the request.

Keep the following in mind: 
- Store the secret as a {{site.konnect_short_name}} Vault reference, not as a plaintext value
- Rotate the secret on a regular schedule
- Combine with egress IP allowlisting so the header alone isn't the only control

### Token-based authentication with OpenID Connect

For APIs where caller identity matters beyond network origin, use the
[OpenID Connect plugin](/plugins/openid-connect/)
to validate JWTs or opaque tokens before forwarding requests upstream.

Kong validates the token at the gateway and can forward claims to your upstream
as headers, so your backend receives a verified identity without needing to
perform its own token validation.

This is particularly useful when:
- Upstream services are shared across multiple calling systems
- You want Kong to act as the centralized token validation and enforcement point
- You need fine-grained authorization based on token claims (scopes, roles, tenant ID)

For an example plugin configuration, see [JWT access token authentication](/plugins/openid-connect/examples/jwt-access-token/)