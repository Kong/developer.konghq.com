This is a Konnect tutorial that requires Dedicated Cloud Gateways access.

If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

You will also need a Personal Access Token: 
Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

Then save that token as an environment variable and your Control Plane URL as environment variables:

```sh
export KONNECT_TOKEN='YOUR KONNECT TOKEN'
export KONNECT_CONTROL_PLANE_URL=https://global.api.konghq.com
```

Create a Control Plane for Dedicated Cloud Gateways:

    {% control_plane_request %}
    url: /v2/control-planes
    status_code: 201
    method: POST
    headers:
      - 'Authorization: Bearer $KONNECT_TOKEN'
      - 'Content-Type: application/json'
    body:
      name: cloud-gateway-control-plane
      description: A test control plane for Dedicated Cloud Gateways.
      cluster_type: CLUSTER_TYPE_CONTROL_PLANE
      cloud_gateway: true
      proxy_urls:
        - host: example.com
          port: 443
          protocol: https
    {% endcontrol_plane_request %}

From the response body, export the `control_plane_id`:

```sh
export CONTROL_PLANE_ID='3e812da0-7c34-4e79-9564-801fce356e5f'
```

Now, create a Dedicated Cloud Gateway network

{% konnect_api_request %}
url: /v2/cloud-gateways/networks
region: global
status_code: 201
method: GET
{% endkonnect_api_request %}

Save the result as an environment variable:

```sh
export NETWORK_ID='YOUR_NETWORK_ID'
```

    
Use the following endpoint to provision a Dedicated Cloud Gateway Data Plane:

    {% control_plane_request %}
    url: /v2/cloud-gateways/configurations
    status_code: 201
    method: PUT
    headers:
      - 'Authorization: Bearer $KONNECT_TOKEN'
      - 'Content-Type: application/json'
    body:
      control_plane_id: $CONTROL_PLANE_ID
      version: "3.6"
      control_plane_geo: us
      dataplane_groups:
        - provider: aws
          region: ap-northeast-1
          cloud_gateway_network_id: $NETWORK_ID
          autoscale:
            kind: autopilot
            base_rps: 100
    {% endcontrol_plane_request %}