{% assign summary='{{site.kic_product_name}} running' %}
{% assign additional_flags = '' %}
{% assign use_values_file = false %}
{% if prereqs.enterprise %}
{% assign use_values_file = true %}
{% endif %}

{% if prereqs.kubernetes.gateway_api == 'experimental' %}
{% assign additional_flags = additional_flags | append:' --set controller.ingressController.env.feature_gates="GatewayAlpha=true"' %}
{% endif %}
{% if prereqs.kubernetes.prometheus %}
{% assign additional_flags = additional_flags | append: ' --set gateway.serviceMonitor.enabled=true --set gateway.serviceMonitor.labels.release=promstack' %}
{% endif %}
{% if prereqs.kubernetes.feature_gates %}
{% assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.feature_gates="' | append: prereqs.kubernetes.feature_gates | append: '"' %}
{% endif %}
{% if prereqs.kubernetes.dump_config %}
{% assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.dump_config=true' %}
{% endif %}

{% if prereqs.kubernetes.env %}
{% for env in prereqs.kubernetes.env %}
{% assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.' | append: env[0] | append: '=' | append: env[1] %}
{% endfor %}
{% endif %}

{% unless use_values_file %}
{% if prereqs.kubernetes.gateway_env %}
{% for env in prereqs.kubernetes.gateway_env %}
{% assign additional_flags = additional_flags | append: ' --set gateway.env.' | append: env[0] | append: '=' | append: env[1] %}
{% endfor %}
{% endif %}
{% endunless %}

{% capture details_content %}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```

{% if prereqs.enterprise %}
1. Create a file named `license.json` containing your {{site.ee_product_name}} license and store it in a Kubernetes secret:

   ```bash
   kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
   kubectl create secret generic kong-enterprise-license --from-file=license=./license.json -n kong
   ```

1. Create a `values.yaml` file:

   ```yaml
   cat <<EOF > values.yaml
   gateway:
     image:
       repository: kong/kong-gateway
     env:{% if prereqs.kubernetes.gateway_env %}{% for env in prereqs.kubernetes.gateway_env %}
       {{ env[0] }}: '{{ env[1] }}'{% endfor %}{% endif %}
       LICENSE_DATA:
         valueFrom:
           secretKeyRef:
             name: kong-enterprise-license
             key: license{% if prereqs.kubernetes.gateway_custom_env %}
     customEnv:{% for env in prereqs.kubernetes.gateway_custom_env %}
       {{ env[0] }}: '{{ env[1] }}'{% endfor %}{% endif %}
   EOF
   ```
{% assign additional_flags = additional_flags | append:' --values ./values.yaml' %}
{% assign summary = summary | append:' (with an Enterprise license)' %}
{% endif %}

1. Install {{ site.kic_product_name }} using Helm:

   ```bash
   helm install kong kong/ingress -n kong --create-namespace{{ additional_flags }}
   ```

{% unless prereqs.kubernetes.skip_proxy_ip %}
1. Set `$PROXY_IP` as an environment variable for future commands:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   echo $PROXY_IP
   ```
{% endunless %}

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
