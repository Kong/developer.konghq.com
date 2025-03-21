{% assign summary='{{site.kic_product_name}} running' %}
{% assign additional_flags = '' %}
{% if prereqs.kubernetes.gateway_api %}
{% assign additional_flags = additional_flags | append:' --set controller.ingressController.env.feature_gates="GatewayAlpha=true"' %}
{% endif %}


{% capture details_content %}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install {{ site.kic_product_name }} using Helm:

   ```bash
   helm install kong kong/ingress -n kong --create-namespace{{ additional_flags }}
   ```

1. Populate `$PROXY_IP` for future commands:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo $PROXY_IP
   ```

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kic.svg' %}
