---
title: "Dedicated Cloud Gateways Reference"
content_type: reference
layout: reference
description: "Dedicated Cloud Gateways are Data Plane nodes that are fully managed by Kong in {{site.konnect_short_name}}."

products:
    - gateway

works_on:
  - konnect

faqs:
  - q: Why is my custom domain attachment failing in {{site.konnect_short_name}}?
    a: |
      A common reason is a missing or misconfigured Certificate Authority Authorization (CAA) record. 
      {{site.konnect_short_name}} uses Google Cloud Public CA (`pki.goog`) to issue certificates. 
      If your domain's CAA record does not authorize this CA, attachment will fail.
  - q: What should I do if my custom domain fails to attach in {{site.konnect_short_name}}?
    a: |
      If your custom domain fails to attach, check whether your domain has a Certificate Authority Authorization (CAA) record that restricts certificate issuance. 
      {{site.konnect_short_name}} uses Google Cloud Public CA (`pki.goog`) to provision SSL/TLS certificates. If the CAA record doesn’t include `pki.goog`, certificate issuance will fail.

      To resolve the issue:
      1. Run `dig CAA yourdomain.com +short` to check for existing CAA records.
      2. If a record exists but doesn’t allow `pki.goog`, update it.
         ```
         yourdomain.com.    CAA    0 issue "pki.goog"
         ```
      3. Wait for DNS propagation and try attaching your domain again.

      If no CAA record exists, no changes are needed. For more details, see the [Let's Encrypt CAA Guide](https://letsencrypt.org/docs/caa/).
  - q: How often is DNS validation refreshed for Dedicated Cloud Gateways?
    a: |
      DNS validation statuses for Dedicated Cloud Gateways are refreshed every 5 minutes.
  - q: How do I delete a custom domain in {{site.konnect_short_name}}?
    a: |
      In {{site.konnect_short_name}}, go to [**Gateway Manager**](https://cloud.konghq.com/us/gateway-manager/), choose a Control Plane, click **Custom Domains**, and use the action menu to delete the domain.

  - q: Why isn’t AWS PrivateLink recommended for connecting Dedicated Cloud Gateway to my upstream services?
    a: |
      AWS PrivateLink offers secure and private connectivity by routing traffic through an endpoint, but it only supports unidirectional communication. 
      This means that Dedicated Cloud Gateway can send requests to your upstream services, but your upstream services cannot initiate communication back to the gateway. 
      For many use cases requiring bidirectional communication—such as callbacks or dynamic interactions between the gateway and your upstream services—this limitation is a blocker. 
      For this reason, PrivateLink is not generally recommended for secure connectivity to your upstream services.

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: Serverless Gateways
    url: /serverless-gateways/
---


## How do Dedicated Cloud Gateways work?

When you create a Dedicated Cloud Gateway, {{site.konnect_short_name}} creates a **Control Plane**. 
This Control Plane, like other {{site.konnect_short_name}} Control Planes, is hosted by {{site.konnect_short_name}}. You can then deploy Data Planes in different [regions](/konnect-geos/#dedicated-cloud-gateways).

Dedicated Cloud Gateways support two different configuration modes:
* **Autopilot Mode:** Configure expected requests per second, and {{site.konnect_short_name}} pre-warms and autoscales the Data Plane nodes automatically.
* **Custom Mode:** Manually specify the instance size, type, and number of nodes per cluster.
<!-- vale off -->
{% mermaid %}
flowchart TD
A(Dedicated Cloud Gateway Control Plane)
B(Managed Data Plane Node \n Region 1)
C(Managed Data Plane Node \n Region 2)

subgraph id1 [Konnect]
A
end

A --auto-scale configuration---> B
A --auto-scale configuration---> C


{% endmermaid %}
<!--vale on -->
## How do I provision a Control Plane?

1. Create a Dedicated Cloud Gateway Control Plane using by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/v2/#/operations/create-control-plane):
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /v2/control-planes/
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  name: cloud-gateway-control-plane
  description: A test Control Plane for Dedicated Cloud Gateways.
  cluster_type: CLUSTER_TYPE_CONTROL_PLAN
  cloud_gateway: true
  proxy_urls:
    - host: example.com
    - port: 443
    - protocol: https
{% endcontrol_plane_request %}
{% endcapture %}
{{request | indent: 3}}
<!--vale on -->

2. Create a Dedicated Cloud Gateway Data Plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/v2/#/operations/create-configuration):
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
      control_plane_id: $CONTROL_PLANE_ID
      version: 3.9
      control_plane_geo: ap-northeast-1
      dataplane_groups:
        - provider: aws 
        - region: na
        - cloud_gateway_network_id: $CLOUD_GATEWAY_NETWORK_ID
        - autoscale: 
          - kind: autopilot
          - base_rps: 100
  {% endcontrol_plane_request %}
{% endcapture %}
{{request | indent: 3}}
<!--vale on -->

## Custom DNS
{{site.konnect_short_name}} integrates domain name management and configuration with [Dedicated Cloud Gateways](/dedicated-cloud-gateways/).

### {{site.konnect_short_name}} configuration

1. Open **Gateway Manager**, choose a Control Plane to open the Overview dashboard, then click **Connect**.
    
    The Connect menu will open and display the URL for the Public Edge DNS. Save this URL.

1. Select **Custom Domains** from the side navigation, then **New Custom Domain**, and enter your domain name.

    Save the value that appears under CNAME. 

### Dedicated Cloud Gateways domain registrar configuration

The following settings must be configured in your domain registrar using the values in {{site.konnect_short_name}}.
For example, in AWS Route 53, it would look like this:
<!--vale off -->
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
  - host: "`_acme-challenge.example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`_acme-challenge.9e454bcfec.acme.gateways.konghq.com`"
    ttl: 300
  - host: "`example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`9e454bcfec.gateways.konghq.com`"
    ttl: 300
{% endtable %}
<!--vale on -->


## Securing backend communication

Dedicated Cloud Gateways only support public networking. If your use case requires private connectivity, consider using [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) with AWS Transit Gateways.

To securely connect a Dedicated Cloud Gateway to your backend, you can inject a shared secret into each request using the [Request Transformer plugin](/plugins/request-transformer).

1. Ensure the backend accepts a known token like an Authorization header.
1. Attach the Request Transformer plugin to the Control Plane and Gateway Service that you want to secure:
<!--vale off-->
{% capture request %}
{% control_plane_request %}
url: /v2/control-planes/{controlPlaneId}/core-entities/services/{serviceId}/plugins
method: POST
status_code: 201
headers:
  - 'accept: application/json'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer ${PAT}'
body:
  name: request-transformer
  config:
    add:
      headers:
        - 'Authorization:Bearer ${secretTokenValue}'
{% endcontrol_plane_request %}
{% endcapture %}
{{ request | indent:3 }}
<!--vale on-->


### AWS Transit Gateway
If you are using Dedicated Cloud Gateways and your upstream services are hosted in AWS, AWS Transit Gateway is the preferred method for most users. For more information and a guide on how to attach your Dedicated Cloud Gateway, see the [Transit Gateways](/dedicated-cloud-gateways/transit-gateways/) documentation.


### Azure VNet Peering
If you are using Dedicated Cloud Gateways and your upstream services are hosted in Azure, VNet Peering is the preferred method for most users. For more information and a guide on how to attach your Dedicated Cloud Gateway, see the [Azure Peering](/dedicated-cloud-gateways/azure-peering/) documentation.

