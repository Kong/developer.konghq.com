{% assign summary='{{site.kic_product_name}} running' %}

{% capture details_content %}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install {{ site.kic_product_name }} using Helm:

   ```bash
   helm install kong kong/ingress -n kong --create-namespace
   ```

1. Populate `$PROXY_IP` for future commands:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}'')
   echo $PROXY_IP
   ```

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kic.svg' %}
