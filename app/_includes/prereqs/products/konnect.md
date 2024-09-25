{% assign summary='Kong Konnect' %}

{% capture details_content %}

This is a Konnect tutorial, if you don't have a Konnect account you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

The following Konnect items are required to complete this tutorial:

* Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**. 
* Control Plane: You can use an existing control plane or [create a new one](https://cloud.konghq.com/us/gateway-manager/create-control-plane) to use for this tutorial. 
* Control Plane ID: You can see your control plane ID by selecting a control plane from the [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/) in Konnect. 

{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}