{% assign summary='{{site.operator_product_name}} running' %}

{% if prereqs.enterprise %}
{% assign summary = summary | append:' (with an Enterprise license)' %}
{% endif %}
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
     --set env.ENABLE_CONTROLLER_KONNECT=true{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```


{% if prereqs.enterprise %}
1. Apply a `KongLicense`. This assumes that your license is available in `./license.json`

   ```
   echo "
   apiVersion: configuration.konghq.com/v1alpha1
   kind: KongLicense
   metadata:
    name: kong-license
   rawLicenseString: '$(cat ./license.json)'
   " | kubectl apply -f -
   ```
{% endif %}
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
