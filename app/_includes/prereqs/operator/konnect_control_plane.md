{% assign summary='Create a KonnectGatewayControlPlane resource' %}

{% capture details_content %}

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
metadata:
  name: gateway-control-plane
spec:
  name: gateway-control-plane{% if include.config.control_plane == 'kic' %}
  cluster_type: CLUSTER_TYPE_K8S_INGRESS_CONTROLLER{% endif %}
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
{% endcapture %}
<!-- vale on -->

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}