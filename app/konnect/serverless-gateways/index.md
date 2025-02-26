---
title: "Serverless Gateway"
content_type: reference
layout: reference
description: | 
    Serverless Gateways are lightweight data plane nodes that are fully managed by {{site.konnect_short_name}}.

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
    a: No. Control Planes that utilize Serverless Gateways can't mix types of Data Planes.
  - q: Can I configure the size of the Data Planes?
    a: No, configuration is handled automatically during the provisoning of the Serverless Gateway Control Plane.
  - q: Does Serverless Gateway support private networking?
    a: No, Serverless Gateways only supports public networking. There are currently no capabilities for private networking between your data centers and hosted Kong data planes. For use cases where private networking is required, [Dedicated Cloud Gateways](/konnect/dedicated-cloud-gateway/) configured with AWS is a better choice.
  - q: Do all plugins work on Serverless Gateway?
    a: |
      * Any plugins that depend on a local agent will not work with serverless gateways.
      * Any plugins that depend on the Status API or on Admin API endpoints will not work.
      * Any plugins or functionality that depend on AWS IAM AssumeRole will have to be configured differently. 

related_resources:
  - text: Konnect Advanced Analytics
    url: /konnect/advanced-analytics/
---

## How do Serverless Gateways work?

When you create a Serverless Gateway, {{site.konnect_short_name}} creates a Control Plane that is hosted by {{site.konnect_short_name}}. Then a hosted Data Plane is provisioned automatically and configured to connect to the Control Plane. 


{% include konnect/deployment-topologies.md %}

## How do I provision a Serverless Gateway?

You can provision a Serverless Gateway by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/v2/#/operations/create-control-plane). 
1. First create a Serverless Control Plane
<!-- vale off -->
{% capture request %}
  {% control_plane_request %}
  url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/vaults/
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

2. Create a Dedicated Cloud Gateway Data Plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/v2/#/operations/create-configuration)

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
1. Locate the option to add a new CNAME record and create the following record using the value saved in the [{{site.konnect_short_name}} configuration](#konnect-configuration) section. For example, in AWS Route 53, it would look like this: 

| Host Name                       | Record Type | Routing Policy | Alias | Evaluate Target Health | Value                                                | TTL |
|---------------------------------|-------------|----------------|-------|------------------------|------------------------------------------------------|-----|
| `my.example.com`             | CNAME       | Simple         | No    | No                     | `9e454bcfec.kongcloud.dev`                     | 300 |

Once a Serverless Gateway custom DNS record has been validated, it will _not_ be refreshed or re-validated. Remove and re-add the custom domain in {{site.konnect_short_name}} to force a re-validation.


### Custom domain attachment and CAA record troubleshooting

If your custom domain attachment fails, check if your domain has a Certificate Authority Authorization (CAA) record restricting certificate issuance. Serverless Gateways use Let's Encrypt CA to provision SSL/TLS certificates. If your CAA record doesn't include the required CA, certificate issuance will fail.

You can resolve this issue by doing the following:

1. Check existing CAA records by running `dig CAA yourdomain.com +short`.
  If a CAA record exists but doesn't allow Let's Encrypt (`letsencrypt.org`), update it.   
2. Update the CAA record, if needed. For example: `yourdomain.com.    CAA    0 issue "letsencrypt.org"`
3. Wait for DNS propagation and retry attaching your domain.

If no CAA record exists, no changes are needed. For more information, see the [Let's Encrypt CAA Guide](https://letsencrypt.org/docs/caa/).