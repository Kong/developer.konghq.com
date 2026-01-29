---
title: "Dedicated Cloud Gateways production readiness checklist"
content_type: reference
layout: reference
description: "Learn how to verify that your Dedicated Cloud Gateway configuration is secure and production-ready."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: PLACEHOLDER!!!!!!
    url: /

tags:
  - dedicated-cloud-gateways
---

This production checklist provides a high-level readiness outline for customers preparing to route production traffic through DCGW. It focuses on Konnect entities and configurations that are specific to DCGW, cloud provider prerequisites, and general pre-production and security hardening steps.

Because every environment is different, this checklist is not exhaustive and should be used as a starting point. Customers should incorporate additional validation as part of a broader launch plan, including testing and readiness for plugins, routes/services, upstream applications, identity providers (IdPs), third-party integrations, and any upstream or operational dependencies.

Preparing your Dedicated Cloud Gateway for production involves the following general steps:
1. [Verify your {{site.konnect_short_name}}](#konnect-configuration) custom domains, data planes, and control planes are configured correctly.
1. [Configure your CIDRs](#cidr-size-requirements) to at least meet minimum requirements.
1. Verify that your cloud provider is configured correctly.
1. Secure your upstream environment.
1. Perform final checks for metrics, logging, load testing, and cutover plan.

These steps are broken down into specific details in the sections that follow.

## {{site.konnect_short_name}} configuration

### Custom Domains

* Verify if the customer has correctly configured the CNAME Domain pointing to the Kong provided address. Check DNS records.
* Verify if the customer has correctly configured the ACME domain for automated certificate management. Ensure the ACME challenge path is accessible.
* Verify if the health of the custom domain is being reported as `healthy` in the Konnect UI. Monitor for certificate issuance and readiness.

### Data planes

* Verify if the Dataplanes are deployed correctly.Check Dataplane registration and logs.
* Verify if the Dataplanes are being reported as in-sync with the Control Plane configuration. Look for configuration drift or synchronization errors.
* Verify the number of Dataplanes deployed meets the customer's minimum redundancy and scale requirements. Compare with initial sizing discussions.

### Control planes

* Verify the Service configuration (Upstream URLs, Health Checks, Load Balancing algorithms) is accurate. Check all services intended for production traffic.
* Verify the Plugin Configuration (e.g., authentication, rate-limiting, logging) is correctly applied and tested. Ensure correct scope (Global, Service, Route).
* Verify the Route configuration (Host, Path, Methods) correctly maps to the intended Services. Test all production routes.
* Verify the TLS/SSL configuration is correctly set up for all required routes/services. Ensure correct certificates are used.

## CIDR size requirements

Kong Dedicated Cloud Gateway (DCGW) deployments require a Virtual Private Cloud (VPC) with a properly sized CIDR block. The following table outlines the minimum VPC CIDR requirements based on the number of Availability Zones (AZs) you plan to use for your DCGW deployment.

Keep the following in mind:
* Cloud Service Providers enforce a minimum subnet mask of /28 (16 IPs) and a maximum of /16 (65,536 IPs) for any VPC subnet.
* The following table reflects the minimum recommended VPC CIDR sizes for Kong DCGW deployments to ensure sufficient IP address space for the required infrastructure.
* Selecting a larger VPC CIDR block provides more flexibility for future growth and expansion.


The following table details the minimum VPC sizes by AZ count:

<!--vale off-->
{% table %}
columns:
  - title: Number of AZs
    key: az_count
  - title: Minimum VPC CIDR
    key: cidr

rows:
  - az_count: 2
    cidr: "/23 (512 IPs)"
  - az_count: 3
    cidr: "/22 (1,024 IPs)"
  - az_count: 4
    cidr: "/22 (1,024 IPs)"
  - az_count: 5
    cidr: "/21 (2,048 IPs)"
{% endtable %}
<!--vale on-->

## AWS provider

### Network

* Verify the number of available IPs in the subnet, considering the peak scale and expected traffic for the customer. Ensure sufficient IP capacity for autoscaling.
* Verify the CIDR range to ensure there are no conflicts with existing customer networks. Cross-reference with customer's network topology.
* Verify Security Group (SG) rules allow necessary inbound/outbound traffic (Control Plane <-> Dataplane, Dataplane <-> Upstream). Strict security posture is required.

### Private networking

#### Transit gateways

* Verify the TGW attachment, route table configurations, and CIDR ranges on the customer network side. Ensure routes exist for Kong's DCGW CIDR.
* Verify if the connectivity is working as expected by sending a test request from DCGW to an internal upstream endpoint. Perform end-to-end ping/HTTP test.
* Verify the TGW firewall/network ACLs are not blocking traffic.

#### VPC peering

Note: VPC Peering is non-transitive; confirm all necessary VPCs are peered or reachable via other means.

* Verify if the customer has shared the correct Resource Configuration (e.g., VPC Endpoint Service name) with Kong.
* Verify if customer has updated all the child configurations for the endpoints they’re looking to route traffic to. Check all services that use Resource Endpoints.
* Verify if the connectivity is working as expected by sending a request to the respective upstream resource.

### Private DNS

#### Private hosted zones

* Verify if the Private Hosted Zone is shared with Kong (DCGW VPC) correctly.
* Verify if the DNS is resolvable from the Kong network by sending a request to the upstream using its private hostname. Perform `nslookup` or connection test.

#### Outbound DNS resolver

* Verify if the Outbound DNS Resolver configuration is updated correctly in Kong's VPC settings. Ensure the correct customer-provided DNS resolvers are targeted.
* Verify if the domain is mapped to the correct DNS resolvers for resolution. Check conditional forwarding rules.
* Verify if the DNS is resolvable from the Kong network by sending a request to the upstream using its private hostname. Perform `nslookup` or connection test.

## Azure provider

### Network

* Verify the number of available IPs in the subnet, considering the peak scale and expected traffic for the customer. Ensure sufficient IP capacity for autoscaling.
* Verify the CIDR range to ensure there are no conflicts with existing customer Vnets. Cross-reference with customer's network topology.

### Vnet Peering & Private DNS Configuration

* Verify Vnet Peering status is Connected and configuration is correct on both sides. 
* Verify Network Security Group (NSG) and Route Table Configuration on the customer network side allows traffic to/from DCGW CIDR. Check for blocked ports or IP ranges.
* Verify the connectivity is working as expected by sending a request to the upstream. Perform end-to-end HTTP test to an internal service.
* Verify the Private DNS configuration (e.g., Private DNS Zones linked to Vnet) to ensure private DNS is resolvable from DCGW. Test resolution of internal Azure hostnames.

## GCP provider

### Network

* Verify the number of available IPs in the subnet, considering the peak scale and expected traffic for the customer. Ensure sufficient IP capacity for autoscaling.
* Verify the CIDR range to ensure there are no conflicts with existing customer VPCs. Cross-reference with customer's network topology.

### GCP VPC Peering

* Verify if the peering connection status and route table configuration are configured correctly on the customer side. Ensure routes are exported/imported correctly.
* Verify if the connectivity is working as expected by sending a request to an internal upstream endpoint. Perform end-to-end HTTP test.
* Verify Firewall rules are configured to allow necessary traffic between the peered networks.

### Private DNS

* Important Note: Cloud DNS peering zones are directional (e.g., DCGW to Customer VPC) and must be configured accordingly. Confirm correct directionality.
* Verify if the Cloud DNS Peering Zone is active and configured correctly in the customer's VPC to allow DCGW to resolve their private domains. 
* Verify if the DNS is resolvable from the Kong network by sending a request to the upstream using its private hostname. Perform `dig` or connection test.

## Securing Dedicated Cloud Gateway upstreams

While Kong manages the Dedicated Cloud Gateway (DCGW) infrastructure, customers are responsible for securing their upstream environments and ensuring that traffic from DCGW is appropriately restricted and authenticated. This shared responsibility model requires precise network and IAM configurations to maintain zero trust principles.

### Ingress Controls: Protecting Public Gateway Endpoint

Customers can apply additional layers of security to further protect the public gateway endpoints such as IPS/IDS, CDN or WAF/WAPI systems. 

### Ingress Controls: Protecting Customer Workloads

Customers can apply the following security controls to restrict and validate incoming traffic from DCGW:
* AWS Security Groups: Apply restrictive ingress rules to allow only traffic from DCGW CIDRs. Gateways can be explicitly whitelisted at NLB or ALB endpoints.
* Network ACLs (NACLs): Add stateless filters to restrict ingress to customer VPCs, requiring matching egress rules for return traffic.
* Transit Gateway (TGW) Route Tables: Ensure that only explicitly routed CIDR blocks or subnets from DCGW are reachable.
* DNS Resolver Rules: Configure Route 53 resolver rules to control which upstream service domains are resolvable from DCGW, enforcing service discovery boundaries.
* Authentication and Authorization: Enforce strong AuthN/AuthZ at all upstream services. Recommended mechanisms include mTLS, JWT, OIDC, and signed requests. TLS should be enabled end-to-end between DCGW and the target service.
* IP Whitelisting at Firewalls or TGW Attachments: Further isolate exposed components by subnet and port at the perimeter level.

### Egress Controls: Limiting What Kong Can Access

To ensure that DCGW can only reach authorized workloads:
* Route Scoping: Only propagate necessary subnets to DCGW; omit others to enforce east-west boundaries.
* Restrictive Security Groups/NACLs: Even if routes exist, SGs and NACLs should deny undesired traffic by source CIDR or port.
* Endpoint Scope: Restrict service exposure to load balancers (e.g., ALBs), blocking direct access to EC2s or backend databases.

### Compromise Response: Rapid Containment Mechanisms

In the unlikely event of a compromise or misconfiguration, customers can rapidly isolate traffic from DCGW:
* TGW / Peering Detachment: Remove or disable the TGW / peering attachment for DCGW VPCs.
* Route Table Null Routing: Blackhole routes to prevent traffic flow from known DCGW CIDRs.
* Security Group Updates: Revoke ingress rules for DCGW source ranges.
* IAM Policy Revocation: If cross-account IAM roles are used, revoke permissions to limit potential control plane misuse.
* DNS Firewall Enforcement: Block DCGW from resolving internal FQDNs using Route 53 DNS Firewall if necessary.

### AWS Transit Gateway (TGW) Safeguards

Customers retain full administrative control over their Transit Gateway and can apply the following safeguards:
* Separate Route Tables per Attachment: Maintain isolation between DCGW and internal services.
* TGW Resource Policies: Limit which principals can modify routes or propagate attachments.
* Monitoring & Logging: Enable VPC Flow Logs and AWS CloudTrail on TGW attachments to audit usage and detect anomalies.

### Infrastructure Hardening (Kong-Managed Environment)

Each customer-dedicated AWS account and VPC provisioned by Kong follows strict security and operational controls:
* IAM Zero Trust: Kong applies least-privilege IAM policies across all infrastructure components.
* Intrusion Detection Agents: All VMs include runtime protection and IDS/IPS agents.
* Audit Logging: CloudTrail is enabled for all API activity.
* Patching Compliance: Instances are regularly updated to meet Kong’s security baselines and CSP-recommended hardening benchmarks.

### Example: Restricting Kong to Load-Balanced Entry Points Only

Customers may choose to expose upstream services only via load balancers (e.g., ALB). This can be enforced by:
* SG/NACL Rules: Permit only ALB IP ranges; block access to internal subnets.
* TGW Scoping: Route only ALB subnets through TGW.
* FQDN + TLS Enforcement: Use host-based routing and TLS hostname validation to prevent direct IP-based access.

## General Pre-Production Final Checks

* Monitoring & Logging: Confirm DCGW logs (Access, Error) are flowing correctly to the Konnect Platform. Check initial log samples.
* Metrics: Confirm DCGW metrics (e.g., latency, error rates) are being collected and reported correctly in Konnect Analytics. Set up initial dashboards.
* Load Testing: Customer has successfully executed representative load/soak tests against the DCGW deployment. Check for unexpected performance degradation or scaling issues.
* Cutover Plan: The detailed traffic cutover plan (DNS TTL changes, staged traffic migration) is finalized and communicated. Ensure rollback plan is also documented.
* Support Channels: Customer has contact information for Kong support and understands the escalation process.