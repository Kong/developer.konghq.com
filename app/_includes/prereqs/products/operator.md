{%- assign summary='{{site.operator_product_name}} running' -%}
{%- if prereqs.enterprise -%}
{%- assign summary = summary | append:' (with an Enterprise license)' -%}
{%- endif -%}
{%- capture license %}
```
echo "
apiVersion: configuration.konghq.com/v1alpha1
kind: KongLicense
metadata:
 name: kong-license
rawLicenseString: '$(cat ./license.json)'
" | kubectl apply -f -
```
{:data-deployment-topology='on-prem'}
{%- endcapture -%}
{%- capture cert-manager -%}
{% include k8s/cert-manager.md %}
{%- endcapture -%}
{%- capture cert -%}
{% include k8s/ca-cert.md %}
{%- endcapture -%}
{% capture details_content %}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

1. Install {{ site.operator_product_name }} using Helm:

{% if include.v_maj == 1 %}

   ```bash
   helm upgrade --install kgo kong/gateway-operator -n kong-system \
     --create-namespace \
     --set env.ENABLE_CONTROLLER_KONNECT=true{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```
   {:data-deployment-topology='konnect'}

   ```bash
   helm upgrade --install kgo kong/gateway-operator -n kong-system \
     --create-namespace{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```
   {:data-deployment-topology='on-prem'}

{% else %}
   
   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }} \
     --set env.ENABLE_CONTROLLER_KONNECT=true{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```
   {:data-deployment-topology='konnect'}

   ```bash
   helm upgrade --install kong-operator kong/kong-operator -n kong-system \
     --create-namespace \
     --set image.tag={{ site.data.operator_latest.release }}{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```
   {:data-deployment-topology='on-prem'}

{% endif %}
{{cert-manager | indent: 3}}
{{cert | indent: 3}}

{% if page.works_on contains 'on-prem' %}
{% if prereqs.enterprise %}
1. Apply a `KongLicense`. This assumes that your license is available in `./license.json`
{:data-deployment-topology='on-prem'}
{{license | indent: 3}}
{% else %}
This tutorial doesn't require a license, but you can add one using `KongLicense`. This assumes that your license is available in `./license.json`.
{:data-deployment-topology='on-prem'}
{{license}}

{%- endif -%}
{%- endif -%}
{%- endcapture -%}

{% if include.raw %}
{{ details_content }}
{% else %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
{% endif %}