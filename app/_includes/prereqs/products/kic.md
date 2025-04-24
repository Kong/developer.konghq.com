{% assign summary='{{site.kic_product_name}} running' %}
{% assign additional_flags = '' %}
{% if prereqs.kubernetes.gateway_api == 'experimental' %}
{% assign additional_flags = additional_flags | append:' --set controller.ingressController.env.feature_gates="GatewayAlpha=true"' %}
{% endif %}
{% if prereqs.kubernetes.prometheus %}
{% assign additional_flags = additional_flags | append: ' --set gateway.serviceMonitor.enabled=true --set gateway.serviceMonitor.labels.release=promstack' %}
{% endif %}
{% if prereqs.kubernetes.feature_gates %}
{% assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.feature_gates="' | append: prereqs.kubernetes.feature_gates | append: '"' %}
{% endif %}

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
   gateway:
     image:
       repository: kong/kong-gateway
     env:
       LICENSE_DATA:
         valueFrom:
           secretKeyRef:
             name: kong-enterprise-license
             key: license
   ```
{% assign additional_flags = additional_flags | append:' --values ./values.yaml' %}
{% assign summary = summary | append:' (with an Enterprise license)' %}
{% endif %}

1. Install {{ site.kic_product_name }} using Helm:

   ```bash
   helm install kong kong/ingress -n kong --create-namespace{{ additional_flags }}
   ```

1. Set `$PROXY_IP` as an environment variable for future commands:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   echo $PROXY_IP
   ```

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}
