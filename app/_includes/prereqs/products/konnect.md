{% assign summary='Kong Konnect' %}

{% capture details_content %}

This is a Konnect tutorial. 
If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. The following Konnect items are required to complete this tutorial:

    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**. 
    * Control Plane: You can use an existing Control Plane or [create a new one](https://cloud.konghq.com/us/gateway-manager/create-control-plane) to use for this tutorial. 
    * Control Plane ID: You can see your Control Plane ID by selecting a Control Plane from the [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/) in Konnect. 
    * A Data Plane node running on `localhost:8000` (default): You can set up Data Plane nodes for your Control Plane from the [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/) in Konnect.

2. Set the personal access token and the Control Plane ID as environment variables:

    ```sh
    export KONNECT_TOKEN=your-token
    export KONNECT_CP_NAME=your-control-plane-name
    ```

{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}