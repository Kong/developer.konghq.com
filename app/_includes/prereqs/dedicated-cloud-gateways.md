This is a Konnect tutorial that requires Dedicated Cloud Gateways access.

If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. The following Konnect items are required to complete this tutorial:
    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
    * Dedicated Cloud Gateway Control Plane: You can use an existing Dedicated Cloud Gateway or [create a new one](https://cloud.konghq.com/gateway-manager/create-gateway) to use for this tutorial.
    * Network ID: The default Dedicated Cloud Gateway network ID can be found in **API Gateway** > **Network**
2. Set these values as environment variables:
    ```sh
    export KONNECT_TOKEN='YOUR KONNECT TOKEN'
    export KONNECT_NETWORK_ID='KONNECT NETWORK ID'
    ```

<!--
You will also need a Personal Access Token: 
Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

Then save that token as an environment variable and your Control Plane URL as environment variables:

```sh
export KONNECT_TOKEN='YOUR KONNECT TOKEN'
export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
```

Create a Control Plane for Dedicated Cloud Gateways:

    {% konnect_api_request %}
    url: /v2/control-planes
    status_code: 201
    method: POST
    body:
      name: cloud-gateway-control-plane
      description: A test control plane for Dedicated Cloud Gateways.
      cluster_type: CLUSTER_TYPE_CONTROL_PLANE
      cloud_gateway: true
      proxy_urls:
        - host: example.com
          port: 443
          protocol: https
    {% endkonnect_api_request %}

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

    {% konnect_api_request %}
    url: /v2/cloud-gateways/configurations
    status_code: 201
    method: PUT
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
    {% endkonnect_api_request %}
-->