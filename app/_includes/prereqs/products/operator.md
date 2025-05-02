{% assign summary='{{site.operator_product_name}} running' %}
{% capture details_content %}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Create a `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Install {{ site.kic_product_name }} using Helm:

   ```bash
   helm upgrade --install kgo kong/gateway-operator -n kong-system --create-namespace  \
     --set image.tag=1.5 \
     --set kubernetes-configuration-crds.enabled=true \
     --set env.ENABLE_CONTROLLER_KONNECT=true
   ```
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
