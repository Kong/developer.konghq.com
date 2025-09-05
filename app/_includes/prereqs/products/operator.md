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

1. Install {{ site.operator_product_name }} using Helm:

{% if prereqs.v_maj == 1 %}

   ```bash
   helm upgrade --install kgo kong/gateway-operator -n kong-system \
     --create-namespace \
     --set env.ENABLE_CONTROLLER_KONNECT=true{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```

{% else %}

   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set env.ENABLE_CONTROLLER_KONNECT=true{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```

{% endif %}

1. Optional: manage webhook certificates with cert-manager

   If you want cert-manager to issue and rotate the admission and conversion webhook certificates, install cert-manager in your cluster and enable cert-manager integration by adding the following value to your Helm command:

   ```bash
   --set global.webhooks.options.certManager.enabled=true
   ```

   If you do not enable this, the chart will generate and inject self-signed certificates automatically. This is fine for development; for production we recommend enabling cert-manager.

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

{% if include.raw %}
{{ details_content }}
{% else %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
{% endif %}
