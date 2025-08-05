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

{% include k8s/helm_install_v2.md raw=true %}

   > **Note:** If you’re working with KGO 1.x use this command:
   > {% include k8s/helm_install_v1.md raw=true %}

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
