{% assign summary='{{site.operator_product_name}} running' %}

{% if prereqs.enterprise %}
{% assign summary = summary | append:' (with an Enterprise license)' %}
{% endif %}
{% capture details_content %}

Install {{ site.operator_product_name }} using Helm:

{% if include.v_maj == 1 %}

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   helm upgrade --install kgo kong/gateway-operator -n kong-system \
     --create-namespace{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```

{% else %}
{: data-deployment-topology="konnect" }
   ```bash
   helm upgrade --install kong-operator ./charts/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag=2.1.0{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_KONNECT=true
   ```

{: data-deployment-topology="on-prem" } 
   ```bash
   helm upgrade --install kong-operator ./charts/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag=2.1.0
   ```

{% endif %}

{% include k8s/cert-manager.md %}

{% include k8s/ca-cert.md %}

{% if prereqs.enterprise %}

1. Apply a `KongLicense`. This assumes that your license is available in `./license.json`

   ```bash
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
