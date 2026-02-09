To manage adopt entities, you first need to create a `KonnectGatewayControlPlane` resource that references our {{site.konnect_short_name}} control plane:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
  namespace: kong
spec:
  source: Mirror
  mirror:
    konnect:
      id: $CONTROL_PLANE_ID
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->