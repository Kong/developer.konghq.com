{% assign summary='Create a KonnectGatewayControlPlane resource' %}

{% capture details_content %}

{% konnect_crd %}
kind: KonnectGatewayControlPlane
metadata:
  name: gateway-control-plane
spec:
  name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}