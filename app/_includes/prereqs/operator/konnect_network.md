{% assign summary='Create a KonnectCloudGatewayNetwork resource' %}

{% capture details_content %}

{% include prereqs/provider-account-id.md %}

Create the `KonnectCloudGatewayNetwork` resource:
<!-- vale off -->
{% konnect_crd %}
kind: KonnectCloudGatewayNetwork
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-network-1
spec:
  name: network1
  cloud_gateway_provider_account_id: '$CLOUD_GATEWAY_PROVIDER_ID'
  availability_zones:
    - euw1-az1
    - euw1-az2
    - euw1-az3
  cidr_block: "192.168.0.0/16"
  region: eu-west-1
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}