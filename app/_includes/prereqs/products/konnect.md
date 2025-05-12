{% assign summary='Kong Konnect' %}

{% capture details_content %}

This is a Konnect tutorial. 
If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. The following Konnect items are required to complete this tutorial:
{% if page.tools contains 'deck' %}
    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
    * Control Plane Name: You can use an existing Control Plane or [create a new one](https://cloud.konghq.com/gateway-manager/create-control-plane) to use for this tutorial.
    * Konnect Proxy URL: By default, a self-hosted Data Plane uses `http://localhost:8000`. You can set up Data Plane nodes for your Control Plane from the [Gateway Manager](https://cloud.konghq.com/gateway-manager/) in Konnect.
{% else %}
    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
    * Control Plane ID: You can use an existing Control Plane or [create a new one](https://cloud.konghq.com/gateway-manager/create-control-plane) to use for this tutorial. You can find your control plane UUID by navigating to the control plane in the Konnect UI or by sending a `GET` request to the [`/control-planes` endpoint](/api/konnect/control-planes/#/operations/list-control-planes).
    * Control Plane URL: `https://us.api.konghq.com`. If needed, replace `us` with your organization's region (for example, `eu` or `au`).
    * Konnect Proxy URL: By default, a self-hosted Data Plane uses `http://localhost:8000`. You can set up Data Plane nodes for your Control Plane from the [Gateway Manager](https://cloud.konghq.com/gateway-manager/) in Konnect.
{% endif %}
2. Set the personal access token, the Control Plane name, the Control Plane URL, and the Konnect proxy URL as environment variables:

{% if page.tools contains 'deck' %}
    ```sh
    export DECK_KONNECT_TOKEN='YOUR KONNECT TOKEN'
    export DECK_KONNECT_CONTROL_PLANE_NAME='YOUR CONTROL PLANE NAME'
    export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
    export KONNECT_PROXY_URL='KONNECT PROXY URL'
    ```
{% else %}
    ```sh
    export KONNECT_TOKEN='YOUR KONNECT TOKEN'
    export KONNECT_CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
    export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
    export KONNECT_PROXY_URL='KONNECT PROXY URL'
    ```
{% endif %}
{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}