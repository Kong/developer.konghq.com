{% assign summary='Create a KonnectAPIAuthConfiguration resource' %}

{% capture details_content %}
<!-- vale off -->
{% konnect_crd %}
create_namespace: kong
kind: KonnectAPIAuthConfiguration
metadata:
  name: konnect-api-auth
spec:
  type: token
  token: '$KONNECT_TOKEN'
  serverURL: us.api.konghq.com
{% endkonnect_crd %}
{% endcapture %}
<!-- vale on -->

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}