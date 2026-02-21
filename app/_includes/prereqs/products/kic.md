{%- assign additional_flags = '' -%}
{%- assign is_konnect = false -%}
{%- if include.topology == "konnect" -%}
{%- assign is_konnect = true -%}
{%- endif -%}
{%- assign use_values_file = false -%}
{%- if prereqs.enterprise or is_konnect -%}
{%- assign use_values_file = true -%}
{%- endif -%}
{%- assign use_kong_license = false -%}
{%- if prereqs.enterprise and include.topology != "konnect" -%}
{%- assign use_kong_license = true -%}
{%- endif -%}
{%- if prereqs.kubernetes.gateway_api == 'experimental' -%}
  {%- assign additional_flags = additional_flags | append:' --set controller.ingressController.env.feature_gates="GatewayAlpha=true"' -%}
{%- endif -%}
{%- if prereqs.kubernetes.prometheus -%}
  {%- assign additional_flags = additional_flags | append: ' --set gateway.serviceMonitor.enabled=true --set gateway.serviceMonitor.labels.release=promstack' -%}
{%- endif -%}
{%- if prereqs.kubernetes.feature_gates -%}
  {%- assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.feature_gates="' | append: prereqs.kubernetes.feature_gates | append: '"' -%}
{%- endif -%}
{%- if prereqs.kubernetes.dump_config -%}
  {%- assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.dump_config=true' -%}
{%- endif -%}
{%- if prereqs.kubernetes.drain_support -%}
  {%- assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.enable_drain_support=true' -%}
{%- endif -%}
{%- if prereqs.kubernetes.env -%}
  {%- for env in prereqs.kubernetes.env -%}
    {%- assign additional_flags = additional_flags | append: ' --set controller.ingressController.env.' | append: env[0] | append: '=' | append: env[1] -%}
  {%- endfor -%}
{%- endif -%}
{%- unless use_values_file -%}
  {%- if prereqs.kubernetes.gateway_env -%}
    {%- for env in prereqs.kubernetes.gateway_env -%}
    {%- assign additional_flags = additional_flags | append: ' --set gateway.env.' | append: env[0] | append: '=' | append: env[1] -%}
    {%- endfor -%}
  {%- endif -%}
{%- endunless -%}
{% capture details_content %}

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   helm repo update
   ```
{% if use_kong_license %}
1. Create a file named `license.json` containing your {{site.ee_product_name}} license and store it in a Kubernetes secret:

   ```bash
   kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
   kubectl create secret generic kong-enterprise-license --from-file=license=./license.json -n kong
   ```
{% endif %}
{% if use_values_file %}
1. Create a `values.yaml` file:

   ```yaml
   cat <<EOF > values.yaml{% if is_konnect %}
   controller:
     ingressController:
       image:
         tag: "3.5"
       env:
         feature_gates: "FillIDs=true"
       konnect:
         license:
           enabled: true
         enabled: true
         controlPlaneID: "$CONTROL_PLANE_ID"
         tlsClientCertSecretName: konnect-client-tls
         apiHostname: "us.kic.api.konghq.com"{% endif %}
   gateway:
     image:
       repository: kong{% if prereqs.enterprise %}/kong-gateway{% endif %}
       tag: "{% if prereqs.enterprise %}{{site.data.gateway_latest.release}}{% else %}{{ site.latest_gateway_oss_version }}{% endif %}"{% if prereqs.kubernetes.gateway_env or is_konnect or use_kong_license %}
     env:{% for env in prereqs.kubernetes.gateway_env %}
       {{ env[0] }}: '{{ env[1] }}'{% endfor %}{% endif %}{% if use_kong_license %}
       LICENSE_DATA:
         valueFrom:
           secretKeyRef:
             name: kong-enterprise-license
             key: license{% endif %}{% if is_konnect %}
       konnect_mode: 'on'
       vitals: "off"
       cluster_mtls: pki
       cluster_telemetry_endpoint: "$CONTROL_PLANE_TELEMETRY:443"
       cluster_telemetry_server_name: "$CONTROL_PLANE_TELEMETRY"
       cluster_cert: /etc/secrets/konnect-client-tls/tls.crt
       cluster_cert_key: /etc/secrets/konnect-client-tls/tls.key
       lua_ssl_trusted_certificate: system
       proxy_access_log: "off"
       dns_stale_ttl: "3600"
     secretVolumes:
        - konnect-client-tls{% endif %}{% if prereqs.kubernetes.gateway_custom_env %}
     customEnv:{% for env in prereqs.kubernetes.gateway_custom_env %}
       {{ env[0] }}: '{{ env[1] }}'{% endfor %}{% endif %}
   EOF
   ```
{%- assign additional_flags = additional_flags | append:' --values ./values.yaml' -%}
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
{%- endcapture -%}
{%- assign summary='{{site.kic_product_name}} running' -%}
{%- if use_kong_license -%}
{%- assign summary = summary | append:' (with an Enterprise license)' -%}
{%- endif -%}
{%- if is_konnect -%}
{%- assign summary = summary | append:' (attached to Konnect)' -%}
{%- endif -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}