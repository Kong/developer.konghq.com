---
title: "{{site.ai_gateway}} 2.0 on Dedicated Cloud Gateways"
content_type: reference
layout: reference
beta: true
min_version:
  ai-gateway: '2.0'
description: "Deploy {{site.ai_gateway}} 2.0 on a fully managed Dedicated Cloud Gateway control plane."
products:
  - gateway
  - ai-gateway
works_on:
  - konnect
breadcrumbs:
  - /dedicated-cloud-gateways/
related_resources:
  - text: "{{site.ai_gateway}} 2.x concepts"
    url: /ai-gateway/ai-gateway-v2-concepts/
  - text: Dedicated Cloud Gateways reference
    url: /dedicated-cloud-gateways/reference/
  - text: Public network architecture
    url: /dedicated-cloud-gateways/public-network/
  - text: Private network architecture
    url: /dedicated-cloud-gateways/private-network/
---

{{site.ai_gateway}} on Dedicated Cloud Gateways gives you a fully managed, single-tenant {{site.ai_gateway}} 2.0 deployment.
Kong hosts the control plane and data planes for you, including scaling, upgrades, and high availability, so you don't have to run and maintain your own {{site.ai_gateway}} data planes.

In addition, {{site.ai_gateway}} on Dedicated Cloud Gateways supports a fully [managed cache for Redis](/dedicated-cloud-gateways/managed-cache/) so you don't have to host Redis infrastructure.
You can use this with any {{site.ai_gateway}} Policy that uses Redis. 

## {{site.ai_gateway}} and {{site.base_gateway}} Cloud Gateways

If you want both {{site.base_gateway}} and {{site.ai_gateway}} to run in a Dedicated Cloud Gateway, you must use separate Dedicated Cloud Gateway control planes for them, instead of combining both on a single control plane.
Sharing networks is best practice.

## Configure an {{site.ai_gateway}} control plane

<!--vale off-->
{% navtabs "configure-ai-gateway" %}
{% navtab "UI" %}
<!--vale on-->
1. In {{site.konnect_short_name}}, click **{{site.ai_gateway}}** in the sidebar.
1. Click **New {{site.ai_gateway}}**.
1. Select **Dedicated Cloud**.
1. Enter a **Display name** for your control plane.
1. For the Node configuration, select the **Provider** and **Region** for your data plane.

   Network range and CIDR block requirements are the same as for a standard Dedicated Cloud Gateway.
   See [CIDR size requirements](/dedicated-cloud-gateways/reference/#cidr-size-requirements) and [Network architecture](/dedicated-cloud-gateways/network-architecture/).
1. Under **API access**, choose **Public** or **Private**.
1. Click **Create**.
<!--vale off-->
{% endnavtab %}
{% navtab "API" %}
<!--vale on-->
1. Create an {{site.ai_gateway}} control plane by sending a `POST` request to the [`/ai-gateways` endpoint](/api/konnect/ai-gateway/#/operations/create-ai-gateway), setting `deployment_type` to `managed`:
<!--vale off-->
{% capture request %}
{% konnect_api_request %}
url: /v1/ai-gateways
method: POST
region: us
status_code: 201
body:
  name: ai-gateway-dcgw
  display_name: AI Gateway Dedicated Cloud
  deployment_type: managed
capture:
  - variable: AI_GATEWAY_ID
    jq: ".id"
{% endkonnect_api_request %}
{% endcapture %}
{{ request | indent: 3 }}
1. Create a Dedicated Cloud Gateway configuration for the {{site.ai_gateway}} control plane by sending a `PUT` request to the [`/cloud-gateways/configurations` endpoint](/api/konnect/cloud-gateways/#/operations/create-configuration):
<!--vale off-->
{% capture request %}
{% konnect_api_request %}
url: /v2/cloud-gateways/configurations
method: PUT
status_code: 200
region: global
body:
  control_plane_id: $AI_GATEWAY_ID
  control_plane_geo: us
  type: ai
  kind: dedicated.v0
  version: '3.14'
  api_access: private
  dataplane_groups:
    - provider: aws
      region: us-east-2
      cloud_gateway_network_id: $CLOUD_GATEWAY_NETWORK_ID
      autoscale:
        kind: autopilot
        base_rps: 100
{% endkonnect_api_request %}
{% endcapture %}
{{ request | indent: 3 }}
{% endnavtab %}
{% endnavtabs %}
<!--vale on-->

Private networking and private DNS work the same way for {{site.ai_gateway}} control planes as they do for standard Dedicated Cloud Gateways.
See the following for instructions:
* [AWS VPC peering](/dedicated-cloud-gateways/aws-vpc-peering/)
* [Transit Gateways](/dedicated-cloud-gateways/transit-gateways/)
* [Set up an AWS resource endpoint connection](/dedicated-cloud-gateways/aws-resource-endpoints/)
* [Private hosted zones](/dedicated-cloud-gateways/private-hosted-zones/)
* [Outbound DNS resolver](/dedicated-cloud-gateways/outbound-dns-resolver/)

## Limitations

Keep the following limitations in mind when using {{site.ai_gateway}} on Dedicated Cloud Gateways:

* {{site.ai_gateway}} 2.0 on Dedicated Cloud Gateways currently only supports AWS.
* [{{site.ai_gateway}} 2.0 managed caches](/dedicated-cloud-gateways/managed-cache/) can only be created, updated, and deleted using the [Cloud Gateways API](/api/konnect/cloud-gateways/).
