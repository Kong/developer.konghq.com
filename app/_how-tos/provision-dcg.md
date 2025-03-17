---
title: Provision a Dedicated Cloud Gateway
content_type: how_to

products:
    - gateway

works_on:
    - konnect
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/

tags:
    - dedicated-cloud-gateway

tldr:
    q: How do I provision a Dedicated Cloud Gateway?
    a: |
      Create a Dedicated Cloud Gateway Control Plane, then configure and provision data plane nodes using the [Dedicated Cloud Gateways API](/api/konnect/cloud-gateways/v2/#/operations/create-configuration).

prereqs:
  skip_product: true
  inline:
    - title: Configure environment variables
      content: |
        Set the following variables: 
        * `KONNECT_TOKEN`: A PAT token can be created from the [tokens](https://cloud.konghq.com/global/account/tokens) page.
        * `KONNECT_CONTROL_PLANE_URL` = Control Plane API URL
        For example: 
        ```sh
        export KONNECT_TOKEN=kpat_hUii8oWeEQWRIGuV6nnUy80A4UT6j51WHx41FLzjRodJfXbJA
        export KONNECT_CONTROL_PLANE_URL=https://global.api.konghq.com
        ```

min_version:
    gateway: '3.9'

---

## 1. Provision your Dedicated Cloud Gateway

Create a Dedicated Cloud Gateway control plane:

<!-- vale off -->
{% control_plane_request %}
url: /v2/control-planes
status_code: 201
method: GET
headers:
    - 'Authorization: Bearer $KONNECT_TOKEN'
    - 'Content-Type: application/json'
body:
    name: cloud-gateway-control-plane
    description: "A test control plane for Dedicated Cloud Gateways."
    cluster_type: CLUSTER_TYPE_CONTROL_PLANE
    cloud_gateway: true
    proxy_urls:
        - host: example.com
          port: 443
          protocol: https
{% endcontrol_plane_request %}
<!-- vale on -->
The response body will contain a `control_plane_id`, export it as an environment variable:
```sh
export KONNECT_CONTROL_PLANE_ID=9c595711-84a7-4fad-b444-d089174cebe1
```



## 2. Validate Control Plane

Verify that the cloud gateway network is available by sending a `GET` request to the `/cloud-gateways/network` endpoint:
<!-- vale off -->
{% control_plane_request %}
url: /v2/cloud-gateways/networks
status_code: 200
method: GET
headers:
    - 'Authorization: Bearer $KONNECT_TOKEN'
{% endcontrol_plane_request %}
<!-- vale on -->
This response will output a `cloud_gateway_network_id` variable, export it as an environment variable: 

```sh
export KONNECT_CLOUD_GATEWAY_NETWORK_ID=9c595711-84a7-4fad-b444-d089174cebe1
```



## 3. Create a Dedicated Cloud Gateway data plane:
<!-- vale off -->
{% control_plane_request %}
url: /v2/cloud-gateways/configurations
status_code: 201
method: PUT
headers:
    - 'Authorization: Bearer $KONNECT_TOKEN'
    - 'Content-Type: application/json'
body:
    control_plane_id: $KONNECT_CONTROL_PLANE_ID
    version: "3.9"
    control_plane_geo: "us"
    dataplane_groups:
        - provider: aws
          region: ap-northeast-1
          cloud_gateway_network_id: $KONNECT_CLOUD_GATEWAY_NETWORK_ID
          autoscale:
              kind: autopilot
              base_rps: 100
{% endcontrol_plane_request %}
<!-- vale on -->
Your cloud gateway is now provisioned.


## 3. Validate

Ensure your Dedicated Cloud Gateway is active:
<!-- vale off -->
{% validation request-check %}
url:  /v2/control-planes/$KONNECT_CONTROL_PLANE_ID
headers:
    - 'Authorization: Bearer $KONNECT_TOKEN'
{% endvalidation %}
<!-- vale on -->
You will receive a `200` with information about your Dedicated Cloud Gateway.
