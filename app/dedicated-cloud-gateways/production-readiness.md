---
title: "Dedicated Cloud Gateways production readiness guide"
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
  - text: Dedicated Cloud Gateway data plane logs
    url: /dedicated-cloud-gateways/konnect-logs/
  - text: Set up a GCP VPC peering connection
    url: /dedicated-cloud-gateways/gcp-vpc-peering/
  - text: Configure an outbound DNS resolver for Dedicated Cloud Gateway
    url: /dedicated-cloud-gateways/outbound-dns-resolver/
  - text: Dedicated Cloud Gateways reference
    url: /dedicated-cloud-gateways/reference/
  - text: Set up an AWS resource endpoint connection
    url: /dedicated-cloud-gateways/aws-resource-endpoints/
  - text: AWS Transit Gateway peering
    url: /dedicated-cloud-gateways/transit-gateways/
  - text: Configure private hosted zones for Dedicated Cloud Gateway
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Set up a GCP private DNS for Dedicated Cloud Gateway
    url: /dedicated-cloud-gateways/gcp-private-dns/
  - text: Set up an AWS VPC peering connection
    url: /dedicated-cloud-gateways/aws-vpc-peering/

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

{% navtabs "konnect-config" %}
{% navtab "Custom domains" %}

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
{% endnavtab %}
{% navtab "Data planes" %}

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
{% endnavtab %}
{% navtab "Control planes" %}

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
{% endnavtab %}
{% endnavtabs %}

## CIDR size requirements

{% include /konnect/cidr-minimum-requirements.md %}

## Cloud provider configuration

See the section for your cloud provider for more information about how to configure your provider for a production instance of Dedicated Cloud Gateways.

### AWS

{% navtabs "AWS" %}
{% navtab "Network" %}

**Action:**
* Verify the number of [available IPs in the subnet](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html), considering your organization's peak scale and expected traffic. Ensure sufficient IP capacity for autoscaling.
* Verify the [CIDR range](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html) to ensure there are no conflicts with your existing networks. Cross-reference this with your network topology.
* Verify that [security group rules](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html) allow necessary inbound/outbound traffic (Control Plane <-> Dataplane, Dataplane <-> Upstream). Strict security posture is required.

{% endnavtab %}
{% navtab "Transit gateways" %}

**Action:**
* Verify the [transit gateway attachment](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpc-attachments.html), [route table configurations](https://docs.aws.amazon.com/vpc/latest/tgw/view-tgw-route-tables.html), and CIDR ranges on your network side. Ensure routes exist for the Dedicated Cloud Gateway CIDR.
* Verify if the connectivity is working as expected by sending a test request from Dedicated Cloud Gateway to an internal upstream endpoint. Perform and end-to-end ping/HTTP test.
* Verify that the transit gateway firewall and [network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html) aren't blocking traffic.


{% endnavtab %}
{% navtab "VPC peering" %}

**Action:**
* Since VPC Peering is non-transitive, confirm that all necessary [VPCs are peered](https://docs.aws.amazon.com/vpc/latest/peering/working-with-vpc-peering.html) or reachable via other means.
* Verify that you've shared the correct [resource configuration](https://docs.aws.amazon.com/vpc/latest/privatelink/resource-configuration-associations.html) (for example, [VPC endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-share-your-services.html) name) with {{site.konnect_short_name}}.
* Verify that you've updated all the [child configurations for the endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/resource-configuration.html) you'll be routing traffic to. Check all services that use resource endpoints.
* Verify if the connectivity is working as expected by sending a request to the respective upstream resource.

{% endnavtab %}
{% navtab "Private hosted zones" %}

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

{% endnavtab %}
{% navtab "Outbound DNS resolver" %}

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
{% endnavtab %}
{% endnavtabs %}

### Azure

{% navtabs "Azure" %}
{% navtab "Network" %}

**Action:**
* Verify the number of [available IPs in the subnet](https://learn.microsoft.com/azure/virtual-network/virtual-network-manage-subnet?tabs=azure-portal#change-subnet-settings), considering your organization's peak scale and expected traffic. Ensure you have sufficient IP capacity for autoscaling.
* Verify that the [CIDR range](https://learn.microsoft.com/azure/virtual-network/virtual-networks-faq#what-address-ranges-can-i-use-in-my-virtual-networks) doesn't interfere with existing your VNet. Cross-reference this with your network topology.

{% endnavtab %}
{% navtab "VNet peering and private DNS" %}

**Action:**
* Verify the VNet peering status is connected in both Azure and {{site.konnect_short_name}}. 
* Verify that your [Azure network security group](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview) and [route table configuration](https://learn.microsoft.com/azure/virtual-network/manage-route-table) on your network side allows traffic to and from the Dedicated Cloud Gateway CIDR. Check for blocked ports or IP ranges.
* Verify the connectivity is working as expected by sending a request to the upstream. Perform an end-to-end HTTP test to an internal service.
* Verify the private DNS configuration (for example, [private DNS zones linked to VNet](https://learn.microsoft.com/azure/dns/private-dns-virtual-network-links)) to ensure private DNS is resolvable from your Dedicated Cloud Gateway. Test that the internal Azure hostnames resolve.
{% endnavtab %}
{% endnavtabs %}

### GCP 

{% navtabs "GCP" %}
{% navtab "Network" %}

**Action:**
* Verify the number of [available IPs in the subnet](https://docs.cloud.google.com/vpc/docs/subnets), considering your organization's peak scale and expected traffic. Ensure there's sufficient IP capacity for autoscaling.
* Verify that the CIDR range doesn't conflict with your existing VPCs. Cross-reference this with your network topology.

{% endnavtab %}
{% navtab "VPC peering" %}

**Action:**
* Verify that your [peering connection status](https://docs.cloud.google.com/vpc/docs/about-peering-connections?hl=en#connection-status) and [route table configuration](https://docs.cloud.google.com/vpc/docs/routes) are configured correctly in Google Virtual Private Cloud. Ensure routes are exported and imported correctly.
* Verify if the connectivity is working as expected by sending a request to an internal upstream endpoint. Perform an end-to-end HTTP test.
* Verify that your firewall rules are configured to allow necessary traffic between the peered networks.

{% endnavtab %}
{% navtab "Private DNS" %}

**Action:**
* [Cloud DNS peering zones](https://docs.cloud.google.com/dns/docs/zones/zones-overview#peering_zones) are directional (for example, Dedicated Cloud Gateway to your organization's VPC) and must be configured accordingly. Confirm correct directionality.
* Verify that the Cloud DNS peering zone is active and configured correctly in the your VPC to allow Dedicated Cloud Gateway to resolve your private domains. 
* Verify if the DNS is resolvable from the {{site.konnect_short_name}} network by sending a request to the upstream using its private hostname. Perform a DNS lookup with `dig` or a connection test.
{% endnavtab %}
{% endnavtabs %}

## Securing Dedicated Cloud Gateway upstreams

While Kong manages the Dedicated Cloud Gateway infrastructure, you are responsible for securing your upstream environments and ensuring that traffic from Dedicated Cloud Gateway is appropriately restricted and authenticated. This shared responsibility model requires precise network and IAM configurations to maintain zero trust principles.

{% navtabs "securing" %}
{% navtab "Ingress" %}

**Action:** Protect the public gateway endpoint and your workloads

**Explanation:**
You can apply additional layers of security to further protect the public gateway endpoints such as IPS/IDS, CDN or WAF/WAPI systems. 

You can apply the following security controls to restrict and validate incoming traffic from Dedicated Cloud Gateway:
* AWS Security Groups: Apply restrictive ingress rules to only allow traffic from Dedicated Cloud Gateway CIDRs. Gateways can be explicitly allowlisted at the network load balancer (NLB) or application load balancer (ALB) endpoints.
* Network ACLs (NACLs): Add stateless filters to restrict ingress to your VPCs, and require matching egress rules for return traffic.
* Transit gateway route tables: Ensure that only explicitly routed CIDR blocks or subnets from Dedicated Cloud Gateway are reachable.
* DNS resolver rules: Configure Route 53 resolver rules to control which upstream service domains are resolvable from Dedicated Cloud Gateway, enforcing service discovery boundaries.
* Authentication and authorization: Enforce strong AuthN/AuthZ at all upstream services. We recommend [mTLS](/plugins/mtls-auth/), [JWT](/plugins/jwt/), [OIDC](/plugins/openid-connect/), and signed requests. TLS should be enabled end-to-end between Dedicated Cloud Gateway and the target service.
* IP allowlisting at Firewalls or transit gateway attachments: Further isolate exposed components by subnet and port at the perimeter level.

{% endnavtab %}
{% navtab "Egress" %}

**Action:** Limit what {{site.konnect_short_name}} can access

**Explanation:**
To ensure that Dedicated Cloud Gateway can only reach authorized workloads, do the following:
* Route scoping: Only propagate necessary subnets to Dedicated Cloud Gateway, omit others to enforce east-west boundaries.
* Restrictive security groups and NACLs: Even if routes exist, security groups and NACLs should deny undesired traffic by source CIDR or port.
* Endpoint scope: Restrict service exposure to load balancers (for example, ALBs), blocking direct access to EC2s or backend databases.

{% endnavtab %}
{% navtab "Compromise response" %}

**Action:** Rapidly isolate traffic from Dedicated Cloud Gateway in the unlikely event of a compromise or misconfiguration.

**Explanation:**
In the unlikely event of a compromise or misconfiguration, you can rapidly isolate traffic from Dedicated Cloud Gateway:
* Transit gateway or VPC peering detachment: Remove or disable the transit gateway or VPC peering attachment for Dedicated Cloud Gateway VPCs in {{site.konnect_short_name}} by navigating to **API Gateways** > **Networks** and select "Delete" from the more options menu.
* Route table null routing: [Black hole routes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Route.html) by pointing them at a non-existent target to prevent traffic flow from known Dedicated Cloud Gateway CIDRs.
* Security group updates: Revoke [ingress rules](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html) for Dedicated Cloud Gateway source ranges.
* IAM policy revocation: If you're using cross-account IAM roles, revoke permissions to limit potential control plane misuse.
* DNS firewall enforcement: Block Dedicated Cloud Gateway from resolving internal FQDNs using [Route 53 DNS firewall](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/gr-configure-manage-firewall-rules.html) if necessary.

{% endnavtab %}
{% navtab "AWS TGW safeguards" %}

You retain full administrative control over your transit gateway and can apply the following safeguards:
* Separate route tables per attachment: Maintain isolation between Dedicated Cloud Gateway and internal services.
* Transit gateway resource policies: Limit which [principals can modify routes or propagate attachments](https://docs.aws.amazon.com/ram/latest/userguide/getting-started-sharing.html#getting-started-sharing-orgs).
* Monitoring and logging: Enable [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html) and [AWS CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-tutorial.html) on transit gateway attachments to audit usage and detect anomalies.

{% endnavtab %}
{% navtab "Kong infrastructure hardening" %}

Each customer-dedicated AWS account and VPC provisioned by Kong follows strict security and operational controls:
* IAM zero trust: Kong applies least-privilege IAM policies across all infrastructure components.
* Intrusion detection agents: All VMs include runtime protection and IDS/IPS agents.
* Audit logging: AWS CloudTrail is enabled for all API activity.
* Patching compliance: Instances are regularly updated to meet Kong’s security baselines and CSP-recommended hardening benchmarks.

{% endnavtab %}
{% navtab "Restrict Kong with load balancing" %}

You can optionally choose to expose upstream services only via load balancers (for example, ALB). This can be enforced by the following:
* Security group and NACL rules: Only permit ALB IP ranges, block access to internal subnets.
* Transit gateway scoping: Only route ALB subnets through transit gateway.
* FQDN and TLS enforcement: Use host-based routing and TLS hostname validation to prevent direct IP-based access.

{% endnavtab %}
{% endnavtabs %}

## General pre-production final checks

**Action:**
* Monitoring and logging: Confirm that Dedicated Cloud Gateway logs (such as access and error) are flowing correctly to {{site.konnect_short_name}}. Check initial log samples.
* Metrics: Confirm Dedicated Cloud Gateway metrics (for example, latency and error rates) are being collected and reported correctly in {{site.konnect_short_name}} Analytics. Set up [initial dashboards](https://cloud.konghq.com/analytics/dashboards).
* Load testing: Execute representative load/soak tests against the Dedicated Cloud Gateway deployment. Check for unexpected performance degradation or scaling issues.
* Cutover plan: Finalize and communicate the detailed traffic cutover plan (for example, DNS TTL changes and staged traffic migration). Ensure a rollback plan is also documented.

<details markdown="1">
<summary><b>How to verify in {{site.konnect_short_name}}</b></summary>

1. In the {{site.konnect_short_name}} sidebar, click **API Gateways**.
1. Select your Dedicated Cloud Gateway.
1. On your Dedicated Cloud Gateway overview, verify that analytics like latency and error rate are collected.
1. In the API Gateway sidebar, click **Control Plane Logs**.
1. Verify that your Dedicated Cloud Gateways are collected. Check the initial log samples.
1. In the {{site.konnect_short_name}} sidebar, click **Observability**.
1. In the Observability sidebar, click **Dashboards**.
1. Set up initial Dedicated Cloud Gateway dashboards.

</details>