---
title: "Serverless Gateway reference"
content_type: reference
layout: reference
description: | 
    Serverless Gateways are lightweight API gateways. Their control plane is hosted by {{site.konnect_short_name}} and data plane nodes are automatically provisioned.

breadcrumbs:
  - /serverless-gateways/
tags:
  - serverless-gateways
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
  - q: Can control planes contain both Serverless Gateway data planes and self-managed data planes?
    a: No. Control planes that use Serverless Gateways can't mix types of data planes.
  - q: Can I configure the size of the data planes?
    a: No, configuration is handled automatically during the provisioning of the Serverless Gateway control plane.
  - q: Does Serverless Gateway support private networking?
    a: |
        No, Serverless Gateways only support public networking. There are currently no capabilities for private networking between your data centers and hosted Kong data planes. For use cases where private networking is required, [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) configured with AWS is a better choice.
  - q: Does plugin functionality change with Serverless Gateways?
    a: |
      * Any plugins that depend on a local agent will not work with Serverless Gateways.
      * Any plugins that depend on the Status API or on Admin API endpoints will not work with Serverless Gateways.
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
  - text: Migrate from V0 to V1
    url: /serverless-gateways/migration/
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Control plane and data plane communication
    url: /gateway/cp-dp-communication/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/

---

Serverless Gateways are lightweight API gateways with a fully hosted control plane in {{site.konnect_short_name}} and automatically-provisioned data plane nodes.
They are highly available, backed by a service-level agreement (SLA), and designed to handle lightweight production workloads. 

Because you don't need to manage any infrastructure, Serverless Gateways are a strong fit for startups, new projects, and teams that want to run low-to-moderate production traffic, as well as for development, testing, and experimentation. 

You can manage your Serverless Gateway nodes under [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in {{site.konnect_short_name}}.

## How do Serverless Gateways work?

When you create a Serverless Gateway, {{site.konnect_short_name}} creates a control plane that is hosted by {{site.konnect_short_name}}. Then, a hosted data plane is provisioned automatically and configured to connect to the control plane. 


{% include konnect/deployment-topologies.md %}

## How do I provision a Serverless Gateway?

To provision a Serverless Gateway, you need to create a serverless control plane and a hosted data plane. 

### {{site.konnect_short_name}} UI

The easiest way to provision a Serverless Gateway is through the {{site.konnect_short_name}} UI, 
where {{site.konnect_short_name}} creates both a control plane and a data plane in one step.

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click the **New** button, then select **New API Gateway**.
1. Select Serverless.
1. Give your Gateway a name and an optional description.
1. Click **Create** to save.

### {{site.konnect_short_name}} APIs

You can use the {{site.konnect_short_name}} APIs to provision control planes and data planes programmatically.

Make sure that you have a [Konnect token](/konnect-api/#konnect-api-authentication) set in your environment.

{% navtabs 'provision-serverless' %}
{% navtab "Serverless V1 beta (US region only)" %}

{:.info}
> **Note**: If you want to migrate an existing V0 control plane to V1, see the [migration guide](/serverless-gateways/migration/).

Create a Serverless Gateway control plane by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/#/operations/create-control-plane):

<!-- vale off -->
{% control_plane_request %}
  url: /v2/control-planes/
  status_code: 201
  method: POST
  region: us
  headers:
      - 'Authorization: Bearer $KONNECT_TOKEN'
      - 'Accept: application/json'
      - 'Content-Type: application/json'
  body:
      name: serverless-gateway-control-plane
      description: A test control plane for Serverless Gateways.
      cluster_type: CLUSTER_TYPE_SERVERLESS_V1
      cloud_gateway: true
      auth_type: pinned_client_certs
{% endcontrol_plane_request %}

Export the generated control plane ID to an environment variable: 

```sh
export CONTROL_PLANE_ID=YOUR-GENERATED-ID-HERE
```

<!--vale on -->
Create a hosted data plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/#/operations/create-configuration):
<!--vale off -->

{% konnect_api_request %}
  url: /v3/cloud-gateways/configurations
  status_code: 201
  region: us
  method: PUT
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
      - 'Authorization: Bearer $KONNECT_TOKEN'
  body:
      control_plane_id: $CONTROL_PLANE_ID
      control_plane_geo: us
      dataplane_groups: 
        - region: us
          provider: aws
      kind: serverless.v1
{% endkonnect_api_request %}

<!--vale on -->

{% endnavtab %}
{% navtab "Global stable version (V0)" %}
	
Create a Serverless Gateway control plane by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/#/operations/create-control-plane):

<!-- vale off -->
{% control_plane_request %}
  url: /v2/control-planes/
  status_code: 201
  method: POST
  headers:
      - 'Authorization: Bearer $KONNECT_TOKEN'
      - 'Accept: application/json'
      - 'Content-Type: application/json'
  body:
      name: serverless-gateway-control-plane
      description: A test control plane for Serverless Gateways.
      cluster_type: CLUSTER_TYPE_SERVERLESS
      cloud_gateway: false
      auth_type: pinned_client_certs
{% endcontrol_plane_request %}

Export the generated control plane ID to an environment variable: 

```
export CONTROL_PLANE_ID=YOUR-GENERATED-ID-HERE
```

<!--vale on -->
Create a hosted data plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/#/operations/create-configuration):
<!--vale off -->

{% konnect_api_request %}
  url: /v3/cloud-gateways/configurations
  status_code: 201
  region: global
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
{% endkonnect_api_request %}
<!--vale on -->

{% endnavtab %}
{% endnavtabs %}

You can now proxy requests through your Serverless Gateway, and it will use the hosted data plane to process traffic.

## How do I configure a custom domain?

{{site.konnect_short_name}} integrates domain name management and configuration with Serverless Gateways.

### {{site.konnect_short_name}} configuration

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the {{site.konnect_short_name}} sidebar.
1. Click a control plane to open the **Overview** dashboard.
1. Click **Connect**.
1. In the **Connect** menu, save the URL from the **Public Edge DNS** field.
1. Navigate to **Custom Domains** in the sidebar.
1. Click **New Custom Domain**.
1. Enter your domain name.

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

Serverless Gateways only support public networking. If your use case requires private connectivity, consider using [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) with AWS Transit Gateways.

To securely connect a Serverless Gateway to your backend, you can inject a shared secret into each request using the [Request Transformer plugin](/plugins/request-transformer).

1. Ensure the backend accepts a known token like an Authorization header.
2. Attach a new plugin to the control plane and Gateway Service that you want to secure:

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
