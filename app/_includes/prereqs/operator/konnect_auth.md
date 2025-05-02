{% assign summary='Create a KonnectAPIAuthConfiguration resource' %}

{% capture details_content %}

{% konnect_crd %}
kind: KonnectAPIAuthConfiguration
metadata:
  name: konnect-api-auth
spec:
  type: token
  token: '$KONNECT_TOKEN'
  serverURL: us.api.konghq.com' | kubectl apply -f -
{% endkonnect_crd %}
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}