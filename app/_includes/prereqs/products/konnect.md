{% assign summary='Kong Konnect' %}

{% capture details_content %}

This is a Konnect tutorial and will require the following values from your Konnect account: 

* Personal Access token(PAT): You can create a personal access token by clicking [here](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**. 
* Control Plane: You can use an existing control plane or [create a new one](https://cloud.konghq.com/us/gateway-manager/create-control-plane) to use for this tutorial. 
* Control Plane ID: You can see your control plane ID by selecting a control plane from the [Gateway Manager](https://cloud.konghq.com/us/gateway-manager/) in Konnect. 

If you don't have a Konnect, you can get started quickly with our onboarding wizard.
[Sign up today](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs)


{% endcapture %}


{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}