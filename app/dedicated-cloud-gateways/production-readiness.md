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

This production checklist provides a high-level readiness outline for customers preparing to route production traffic through Dedicated Cloud Gateway. It focuses on Konnect entities and configurations that are specific to Dedicated Cloud Gateway, cloud provider prerequisites, and general pre-production and security hardening steps.

Because every environment is different, this checklist is not exhaustive and should be used as a starting point. Customers should incorporate additional validation as part of a broader launch plan, including testing and readiness for plugins, routes/services, upstream applications, identity providers (IdPs), third-party integrations, and any upstream or operational dependencies.

Preparing your Dedicated Cloud Gateway for production involves the following general steps:
1. [Verify your {{site.konnect_short_name}}](#konnect-configuration) custom domains, data planes, and control planes are configured correctly.
1. [Configure your CIDRs](#cidr-size-requirements) to at least meet minimum requirements.
1. Verify that your cloud provider is configured correctly.
1. [Secure your upstream environment.](#securing-dedicated-cloud-gateway-upstreams)
1. [Perform final checks](#general-pre-production-final-checks) for metrics, logging, load testing, and cutover plan.

These steps are broken down into specific details in the sections that follow.

## {{site.konnect_short_name}} configuration

### Custom domains

**Action:** 
If you're using a [custom domain](/dedicated-cloud-gateways/reference/#custom-dns) with your Dedicated Cloud Gateway, you'll need to do the following:
* Verify that the Kong-provided CNAME domain is correct in your DNS records.
* Verify that ACME domain is correct and the challenge path is accessible.
* Verify that the custom domain is healthy in the {{site.konnect_short_name}} UI.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Select your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Custom Domains**.
1. Verify that the status of your custom domain displays as `HEALTHY`. Monitor this for certificate issuance and readiness.
1. Click the more options menu icon next to your custom domain.
1. Click **Configure DNS**.
1. The first CNAME value should match the CNAME domain in your DNS records.
1. The second CNAME value is the ACME domain you must use for automated certificate management. Make sure that this challenge path is accessible.

</details>

### Data planes

**Action:**
* Verify that the data planes are deployed correctly. Check the data plane registration and logs.
* Verify that the data planes are being reported as in-sync with the control plane configuration. Look for configuration drift or synchronization errors.
* Verify the number of data planes deployed meets the your organization's minimum redundancy and scale requirements. Compare these numbers with initial sizing discussions.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Select your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Data Plane Nodes**.
1. Verify that the number of data planes meets your organization's minimum redundancy and scale requirements. Compare these numbers with initial sizing discussions.
1. Verify that data plane nodes have the following statuses:
   * **Connected:** `Connected`
   * **Sync Status:** `In Sync`
   * **Errors:** None
1. In the API Gateway sidebar, click **Control Plane Logs**. 
1. Verify that the data plane logs don't report any deployment errors.

</details>

### Control planes

**Action:**
* Verify that all Services intended for production traffic have accurate configuration, including upstream URLs, health checks, and load balancing algorithms.
* Verify that production plugins are configured correctly, including authentication, rate limiting, and logging plugins. Make sure plugins are scoped correctly.
* Verify that production Routes correctly map to Services and the Route host, path, and methods are accurate. Test all production Routes.
* Verify the [TLS/SSL configuration](/gateway/entities/route/#tls-route-configuration) is configured correctly for all production Routes and Services. Ensure the correct certificates are used.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Select your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Gateway Services**.
1. To verify production Service configuration, do the following:
   1. Click a Service that is intended for production traffic.
   1. Click the **Configuration** tab.
   1. Verify that your Service upstream URLs, health checks, and load balancing configurations are accurate. 
   1. Repeat these steps for all production Services.
1. In the API Gateway sidebar, click **Routes**.
1. To verify production Route configuration, do the following:
   1. Click a Route that is intended for production traffic.
   1. Click the **Configuration** tab.
   1. Verify that your Route host, path, and methods correctly map to the corresponding Services. 
   1. If you're using TLS/SSL, verify that these are configured correctly with [Certificates or SNIs associated with the Route](/gateway/entities/route/#tls-route-configuration).
   1. Repeat these steps for all production Routes.
1. In the API Gateway sidebar, click **Plugins**.
1. To verify production plugin configuration, do the following:
   1. Click a plugin that is intended for production traffic.
   1. Click the **Configuration** tab.
   1. Verify that your plugins are configured correctly and have the correct scope. 
   1. Repeat these steps for all production plugins.
1. Test all production Routes by sending a request and verifying that the response is as expected based on the Route and Service configurations and the applied plugins.

</details>

## CIDR size requirements

{% include /konnect/cidr-minimum-requirements.md %}

## AWS provider

### Network

**Action:**
* Verify the number of [available IPs in the subnet](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html), considering your organization's peak scale and expected traffic. Ensure sufficient IP capacity for autoscaling.
* Verify the [CIDR range](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html) to ensure there are no conflicts with your existing networks. Cross-reference this with your network topology.
* Verify that [security group rules](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html) allow necessary inbound/outbound traffic (Control Plane <-> Dataplane, Dataplane <-> Upstream). Strict security posture is required.

### Private networking

#### Transit gateways

**Action:**
* Verify the [transit gateway attachment](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpc-attachments.html), [route table configurations](https://docs.aws.amazon.com/vpc/latest/tgw/view-tgw-route-tables.html), and CIDR ranges on your network side. Ensure routes exist for the Dedicated Cloud Gateway CIDR.
* Verify if the connectivity is working as expected by sending a test request from Dedicated Cloud Gateway to an internal upstream endpoint. Perform and end-to-end ping/HTTP test.
* Verify that the transit gateway firewall and [network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html) aren't blocking traffic.

#### VPC peering

**Action:**
* Since VPC Peering is non-transitive, confirm that all necessary [VPCs are peered](https://docs.aws.amazon.com/vpc/latest/peering/working-with-vpc-peering.html) or reachable via other means.
* Verify that you've shared the correct [resource configuration](https://docs.aws.amazon.com/vpc/latest/privatelink/resource-configuration-associations.html) (for example, [VPC endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-share-your-services.html) name) with {{site.konnect_short_name}}.
* Verify that you've updated all the [child configurations for the endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/resource-configuration.html) you'll be routing traffic to. Check all services that use resource endpoints.
* Verify if the connectivity is working as expected by sending a request to the respective upstream resource.

### Private DNS

#### Private hosted zones

**Action:**
* Verify that the [private hosted zone is shared](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-associate-vpcs.html) with the Dedicated Cloud Gateway VPC correctly.
* Verify if the DNS is resolvable from the Dedicated Cloud Gateway network by sending a request to the upstream using its private hostname. [Perform `nslookup`](https://learn.microsoft.com/windows-server/administration/windows-commands/nslookup) or a connection test.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Select your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Networks**.
1. From the more options menu next to your network, select "Configure private DNS".
1. Verify that the private hosted zone configuration matches what's configured in AWS.

</details>

#### Outbound DNS resolver

**Action:**
* Verify if the outbound DNS resolver configuration is updated correctly in the Dedicated Cloud Gateway's VPC settings. Ensure that your provided DNS resolvers are targeted.
* Verify if the domain is mapped to the correct DNS resolvers for resolution. Check conditional forwarding rules.
* Verify if the DNS is resolvable from the Dedicated Cloud Gateway network by sending a request to the upstream using its private hostname. [Perform `nslookup`](https://learn.microsoft.com/windows-server/administration/windows-commands/nslookup) or a connection test.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Select your Dedicated Cloud Gateway.
1. In the API Gateway sidebar, click **Networks**.
1. From the more options menu next to your network, select "Configure private DNS".
1. Click **Outbound DNS resolver**.
1. Verify that the outbound DNS resolver configuration matches what's configured in AWS.

</details>

## Azure provider

### Network

**Action:**
* Verify the number of [available IPs in the subnet](https://learn.microsoft.com/azure/virtual-network/virtual-network-manage-subnet?tabs=azure-portal#change-subnet-settings), considering your organization's peak scale and expected traffic. Ensure you have sufficient IP capacity for autoscaling.
* Verify that the [CIDR range](https://learn.microsoft.com/azure/virtual-network/virtual-networks-faq#what-address-ranges-can-i-use-in-my-virtual-networks) doesn't interfere with existing VNETs. Cross-reference this with your network topology.

### VNet peering and private DNS configuration

**Action:**
* Verify Vnet Peering status is Connected and configuration iin both Azure and {{site.konnect_short_name}}. 
* Verify Network Security Group (NSG) and Route Table Configuration on the customer network side allows traffic to/from Dedicated Cloud Gateway CIDR. Check for blocked ports or IP ranges.
* Verify the connectivity is working as expected by sending a request to the upstream. Perform end-to-end HTTP test to an internal service.
* Verify the Private DNS configuration (e.g., Private DNS Zones linked to Vnet) to ensure private DNS is resolvable from Dedicated Cloud Gateway. Test resolution of internal Azure hostnames.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>



</details>

## GCP provider

### Network

* Verify the number of available IPs in the subnet, considering the peak scale and expected traffic for the customer. Ensure sufficient IP capacity for autoscaling.
* Verify the CIDR range to ensure there are no conflicts with existing customer VPCs. Cross-reference with customer's network topology.

**Action:**

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>



</details>

### GCP VPC Peering

* Verify if the peering connection status and route table configuration are configured correctly on the customer side. Ensure routes are exported/imported correctly.
* Verify if the connectivity is working as expected by sending a request to an internal upstream endpoint. Perform end-to-end HTTP test.
* Verify Firewall rules are configured to allow necessary traffic between the peered networks.

**Action:**

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>



</details>

### Private DNS

* Important Note: Cloud DNS peering zones are directional (e.g., Dedicated Cloud Gateway to Customer VPC) and must be configured accordingly. Confirm correct directionality.
* Verify if the Cloud DNS Peering Zone is active and configured correctly in the customer's VPC to allow Dedicated Cloud Gateway to resolve their private domains. 
* Verify if the DNS is resolvable from the Kong network by sending a request to the upstream using its private hostname. Perform `dig` or connection test.

**Action:**

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>



</details>

## Securing Dedicated Cloud Gateway upstreams

While Kong manages the Dedicated Cloud Gateway (Dedicated Cloud Gateway) infrastructure, customers are responsible for securing their upstream environments and ensuring that traffic from Dedicated Cloud Gateway is appropriately restricted and authenticated. This shared responsibility model requires precise network and IAM configurations to maintain zero trust principles.

### Ingress Controls: Protecting Public Gateway Endpoint

Customers can apply additional layers of security to further protect the public gateway endpoints such as IPS/IDS, CDN or WAF/WAPI systems. 

### Ingress Controls: Protecting Customer Workloads

Customers can apply the following security controls to restrict and validate incoming traffic from Dedicated Cloud Gateway:
* AWS Security Groups: Apply restrictive ingress rules to allow only traffic from Dedicated Cloud Gateway CIDRs. Gateways can be explicitly whitelisted at NLB or ALB endpoints.
* Network ACLs (NACLs): Add stateless filters to restrict ingress to customer VPCs, requiring matching egress rules for return traffic.
* Transit Gateway (TGW) Route Tables: Ensure that only explicitly routed CIDR blocks or subnets from Dedicated Cloud Gateway are reachable.
* DNS Resolver Rules: Configure Route 53 resolver rules to control which upstream service domains are resolvable from Dedicated Cloud Gateway, enforcing service discovery boundaries.
* Authentication and Authorization: Enforce strong AuthN/AuthZ at all upstream services. Recommended mechanisms include mTLS, JWT, OIDC, and signed requests. TLS should be enabled end-to-end between Dedicated Cloud Gateway and the target service.
* IP Whitelisting at Firewalls or TGW Attachments: Further isolate exposed components by subnet and port at the perimeter level.

### Egress Controls: Limiting What Kong Can Access

To ensure that Dedicated Cloud Gateway can only reach authorized workloads:
* Route Scoping: Only propagate necessary subnets to Dedicated Cloud Gateway; omit others to enforce east-west boundaries.
* Restrictive Security Groups/NACLs: Even if routes exist, SGs and NACLs should deny undesired traffic by source CIDR or port.
* Endpoint Scope: Restrict service exposure to load balancers (e.g., ALBs), blocking direct access to EC2s or backend databases.

### Compromise Response: Rapid Containment Mechanisms

In the unlikely event of a compromise or misconfiguration, customers can rapidly isolate traffic from Dedicated Cloud Gateway:
* TGW / Peering Detachment: Remove or disable the TGW / peering attachment for Dedicated Cloud Gateway VPCs.
* Route Table Null Routing: Blackhole routes to prevent traffic flow from known Dedicated Cloud Gateway CIDRs.
* Security Group Updates: Revoke ingress rules for Dedicated Cloud Gateway source ranges.
* IAM Policy Revocation: If cross-account IAM roles are used, revoke permissions to limit potential control plane misuse.
* DNS Firewall Enforcement: Block Dedicated Cloud Gateway from resolving internal FQDNs using Route 53 DNS Firewall if necessary.

### AWS Transit Gateway (TGW) Safeguards

Customers retain full administrative control over their Transit Gateway and can apply the following safeguards:
* Separate Route Tables per Attachment: Maintain isolation between Dedicated Cloud Gateway and internal services.
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

* Monitoring & Logging: Confirm Dedicated Cloud Gateway logs (Access, Error) are flowing correctly to the Konnect Platform. Check initial log samples.
* Metrics: Confirm Dedicated Cloud Gateway metrics (e.g., latency, error rates) are being collected and reported correctly in Konnect Analytics. Set up initial dashboards.
* Load Testing: Customer has successfully executed representative load/soak tests against the Dedicated Cloud Gateway deployment. Check for unexpected performance degradation or scaling issues.
* Cutover Plan: The detailed traffic cutover plan (DNS TTL changes, staged traffic migration) is finalized and communicated. Ensure rollback plan is also documented.
* Support Channels: Customer has contact information for Kong support and understands the escalation process.

**Action:**

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>



</details>