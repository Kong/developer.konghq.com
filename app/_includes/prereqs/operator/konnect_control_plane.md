{% assign summary='Create a KonnectGatewayControlPlane resource' %}

{% capture details_content %}

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
spec:
  createControlPlaneRequest:
    name: gateway-control-plane{% if include.config.control_plane == 'kic' %}
    clusterType: CLUSTER_TYPE_K8S_INGRESS_CONTROLLER{% endif %}
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
{% endcapture %}
<!-- vale on -->

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}