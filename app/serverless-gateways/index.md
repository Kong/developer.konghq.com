---
title: "Serverless Gateway"
content_type: reference
layout: reference
description: | 
    Serverless gateways are lightweight API gateways. Their Control Plane is hosted by {{site.konnect_short_name}} and Data Plane nodes are automatically provisioned.

breadcrumbs:
  - /konnect/
tags:
  - serverless-gateway
  - hybrid-mode
  - data-plane
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
    a: |
        No, serverless gateways only supports public networking. There are currently no capabilities for private networking between your data centers and hosted Kong Data Planes. For use cases where private networking is required, [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) configured with AWS is a better choice.
  - q: Does plugin functionality change with serverless gateways?
    a: |
      * Any plugins that depend on a local agent will not work with serverless gateways.
      * Any plugins that depend on the Status API or on Admin API endpoints will not work with serverless gateways.
      * Any plugins or functionality that depend on AWS IAM AssumeRole will have to be configured differently. 
  - q: My serverless custom domain attachment failed, how do I troubleshoot it?
    a: |
      If your custom domain attachment fails, check if your domain has a Certificate Authority Authorization (CAA) record restricting certificate issuance. Serverless Gateways use Let's Encrypt CA to provision SSL/TLS certificates. If your CAA record doesn't include the required CA, certificate issuance will fail.
      You can resolve this issue by doing the following:

        1. Check existing CAA records by running `dig CAA yourdomain.com +short`.
          If a CAA record exists but doesn't allow Let's Encrypt (`letsencrypt.org`), update it.   
        2. Update the CAA record, if needed. For example: `yourdomain.com.    CAA    0 issue "letsencrypt.org"`
        3. Wait for DNS propagation and retry attaching your domain.

        If no CAA record exists, no changes are needed. For more information, see the [Let's Encrypt CAA Guide](https://letsencrypt.org/docs/caa/).
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Control Plane and Data Plane communication
    url: /gateway/cp-dp-communication/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/

---
Serverless gateways are lightweight API gateways. Their Control Plane is hosted by {{site.konnect_short_name}} and Data Plane nodes are automatically provisioned. Serverless gateways are ideal for developers who want to test or experiment in a pre-production environment.

Serverless gateways offer the following benefits:
* {{site.konnect_short_name}} manages provisioning and placement.
* Can be deployed in under 30 seconds.
* Access to {{site.base_gateway}} plugins.

You can manage your serverless gateway nodes in [Gateway Manager](https://cloud.konghq.com/gateway-manager/).
## How do serverless gateways work?

When you create a serverless gateway, {{site.konnect_short_name}} creates a Control Plane that is hosted by {{site.konnect_short_name}}. Then, a hosted Data Plane is provisioned automatically and configured to connect to the Control Plane. 


{% include konnect/deployment-topologies.md %}

## How do I provision a serverless gateway?

Provisioning a serverless gateway includes creating the serverless Control Plane and hosted Data Plane.
	
1. Create a serverless gateway Control Plane by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/#/operations/create-control-plane).
<!-- vale off -->
{% capture request1 %}
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
      description: A test Control Plane for Serverless Gateways.
      cluster_type: CLUSTER_TYPE_SERVERLESS
      cloud_gateway: false
      auth_type: pinned_client_certs
{% endcontrol_plane_request %}
{% endcapture %}

{{ request1 | indent:3 }}
<!--vale on -->
2. Create a hosted Data Plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/#/operations/create-configuration):
<!--vale off -->
{% capture request2 %}
{% control_plane_request %}
  url: /v2/cloud-gateways/configurations
  status_code: 201
  method: PUT
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Authorization: Bearer $KONNECT_TOKEN'
  body:
      control_plane_id: $CONTROL_PLANE_ID
      control_plane_geo: us
      dataplane_groups: 
        - region: na
      kind: serverless.v0
{% endcontrol_plane_request %}
{% endcapture %}

{{ request2 | indent:3 }}
<!--vale on -->

## How do I configure a custom domain?

{{site.konnect_short_name}} integrates domain name management and configuration with Serverless Gateways.

### {{site.konnect_short_name}} configuration

1. Open **Gateway Manager**, choose a Control Plane to open the **Overview** dashboard, then click **Connect**.
    
    The **Connect** menu will open and display the URL for the **Public Edge DNS**. Save this URL.

1. Select **Custom Domains** from the side navigation, then **New Custom Domain**, and enter your domain name.

    Save the value that appears under **CNAME**. 

### Domain registrar configuration

1. Log in to your domain registrar's dashboard.
1. Navigate to the DNS settings section. This area might be labeled differently depending on your registrar.
1. Locate the option to add a new CNAME record and create the following record using the CNAME value from {{site.konnect_short_name}} that you saved previously. For example, in AWS Route 53, it would look like this: 

{% table %}
columns:
  - title: Host Name
    key: host
  - title: Record Type
    key: type
  - title: Routing Policy
    key: routing
  - title: Alias
    key: alias
  - title: Evaluate Target Health
    key: health
  - title: Value
    key: value
  - title: TTL
    key: ttl
rows:
  - host: "`my.example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`9e454bcfec.kongcloud.dev`"
    ttl: 300
{% endtable %}

Once a Serverless Gateway custom DNS record has been validated, it will _not_ be refreshed or re-validated. Remove and re-add the custom domain in {{site.konnect_short_name}} to force a re-validation.

## Securing backend communication

Serverless gateways only support public networking. If your use case requires private connectivity, consider using [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) with AWS Transit Gateways.

To securely connect a serverless gateway to your backend, you can inject a shared secret into each request using the [Request Transformer plugin](/plugins/request-transformer).

1. Ensure the backend accepts a known token like an Authorization header.
2. Attach a new plugin to the Control Plane and Gateway Service that you want to secure:

<!--vale off-->
{% control_plane_request %}
url: /v2/control-planes/{controlPlaneId}/core-entities/services/{serviceId}/plugins
method: POST
status_code: 201
headers:
  - 'accept: application/json'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  name: request-transformer
  config:
    add:
      headers:
        - 'Authorization:Bearer $SECRET_TOKEN_VALUE'
{% endcontrol_plane_request %}
<!--vale on-->

## Limits
Serverless Gateways have the following limits:
* Request rate limit: Serverless Gateways support up to 100 requests per second (RPS) per gateway.
* Maximum request size: Incoming requests are limited to a maximum payload size of 10MB.
For workloads that exceed these limits, consider using [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) for higher throughput and larger request sizes.