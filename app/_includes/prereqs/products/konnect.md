{% assign summary='Kong Konnect' %}

{% capture details_content %}

This is a Konnect tutorial. 
If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. The following Konnect items are required to complete this tutorial:

    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
    * Control Plane Name: You can use an existing Control Plane or [create a new one](https://cloud.konghq.com/gateway-manager/create-control-plane) to use for this tutorial.
    * Konnect Proxy URL: By default, a self-hosted Data Plane uses `http://localhost:8000`. You can set up Data Plane nodes for your Control Plane from the [Gateway Manager](https://cloud.konghq.com/gateway-manager/) in Konnect.

2. Set the personal access token, the Control Plane Name and the Konnect proxy URL as environment variables:

    ```sh
    export KONNECT_TOKEN=your-token
    export KONNECT_CP_NAME=your-control-plane-name
    export KONNECT_PROXY_URL=konnect-proxy-url
    ```

{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}