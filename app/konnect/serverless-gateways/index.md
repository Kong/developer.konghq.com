---
title: "Serverless Gateway"
content_type: reference
layout: reference
description: | 
    Serverless gateways are lightweight API gateways. Their control plane is hosted by {{site.konnect_short_name}} and data plane nodes are automatically provisioned.

no_version: true
products:
    - gateway
works_on:
    - konnect
api_specs:
    - konnect/control-planes-config
faqs:
  - q: Will a new Serverless Gateway be provisioned in the same region as {{site.konnect_short_name}}?
    a: Deployment on the same region is not guaranteed.
  - q: What {{site.base_gateway}} version do Serverless Gateways run?
    a: The {{site.base_gateway}} version can't be configured. The default is always `latest` and will be automatically upgraded.
  - q: Can Control Planes contain both Serverless Gateway Data Planes and self-managed Data Planes?
    a: No. Control Planes that use Serverless Gateways can't mix types of Data Planes.
  - q: Can I configure the size of the Data Planes?
    a: No, configuration is handled automatically during the provisioning of the Serverless Gateway Control Plane.
  - q: Does Serverless Gateway support private networking?
    a: No, Serverless Gateways only supports public networking. There are currently no capabilities for private networking between your data centers and hosted Kong data planes. For use cases where private networking is required, [Dedicated Cloud Gateways](/konnect/dedicated-cloud-gateways/) configured with AWS is a better choice.
  - q: Do all plugins work on Serverless Gateway?
    a: |
      * Any plugins that depend on a local agent will not work with serverless gateways.
      * Any plugins that depend on the Status API or on Admin API endpoints will not work.
      * Any plugins or functionality that depend on AWS IAM AssumeRole will have to be configured differently. 

related_resources:
  - text: Dedicated Cloud Gateways
    url: /konnect/dedicated-cloud-gateways/
  - text: Kong Gateway control plane and data plane communication
    url: /gateway/cp-dp-communication/
---
Serverless gateways are lightweight API gateways. Their control plane is hosted by {{site.konnect_short_name}} and data plane nodes are automatically provisioned. Serverless gateways are ideal for developers who want to test or experiment in a pre-production environment.

Serverless gateways offer the following benefits:
* {{site.konnect_short_name}} manages provisioning and placement.
* Can be deployed in under 30 seconds.
* Access to {{site.base_gateway}} plugins.

You can manage your serverless gateway nodes in [Gateway Manager](https://cloud.konghq.com/gateway-manager/).
## How do serverless gateways work?

When you create a serverless gateway, {{site.konnect_short_name}} creates a Control Plane that is hosted by {{site.konnect_short_name}}. Then, a hosted Data Plane is provisioned automatically and configured to connect to the Control Plane. 


{% include konnect/deployment-topologies.md %}

## How do I provision a serverless gateway?

You can provision a Serverless Gateway by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/v2/#/operations/create-control-plane). 
1. First create a Serverless Control Plane
<!-- vale off -->
{% capture request %}
  {% control_plane_request %}
  url: /v2/control-planes/$CONTROL_PLANE_ID/
  status_code: 201
  method: POST
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Authorization: Bearer $KONNECT_TOKEN'
  body:

      name: serverless-gateway-control-plane
      description: A test control plane for Serverless Gateways.
      cluster_type: CLUSTER_TYPE_SERVERLESS
      cloud_gateway: false
      auth_type: pinned_client_certs
  {% endcontrol_plane_request %}
  {% endcapture %}

{{request | indent: 3}}
<!--vale on -->

2. Create a hosted Data Plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/v2/#/operations/create-configuration):

<!--vale off -->
{% capture request %}
  {% control_plane_request %}
  url: /v2/cloud-gateways/configurations
  status_code: 201
  method: PUT
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Authorization: Bearer $KONNECT_TOKEN'
  body:
      control_plane_id: $CONTROL_PLANE_OD
      control_plane_geo: us
      dataplane_groups: 
        - region: na
      kind: serverless.v0
  {% endcontrol_plane_request %}
  {% endcapture %}

{{request | indent: 3}}
<!--vale on -->

## How do I configure a custom domain?

{{site.konnect_short_name}} integrates domain name management and configuration with Serverless Gateways.

### {{site.konnect_short_name}} configuration

1. Open **Gateway Manager**, choose a control plane to open the **Overview** dashboard, then click **Connect**.
    
    The **Connect** menu will open and display the URL for the **Public Edge DNS**. Save this URL.

1. Select **Custom Domains** from the side navigation, then **New Custom Domain**, and enter your domain name.

    Save the value that appears under **CNAME**. 

### Domain registrar configuration

1. Log in to your domain registrar's dashboard.
1. Navigate to the DNS settings section. This area might be labeled differently depending on your registrar.
1. Locate the option to add a new CNAME record and create the following record using the CNAME value from {{site.konnect_short_name}} that you saved previously. For example, in AWS Route 53, it would look like this: 

| Host Name                       | Record Type | Routing Policy | Alias | Evaluate Target Health | Value                                                | TTL |
|---------------------------------|-------------|----------------|-------|------------------------|------------------------------------------------------|-----|
| `my.example.com`             | CNAME       | Simple         | No    | No                     | `9e454bcfec.kongcloud.dev`                     | 300 |

Once a Serverless Gateway custom DNS record has been validated, it will _not_ be refreshed or re-validated. Remove and re-add the custom domain in {{site.konnect_short_name}} to force a re-validation.

