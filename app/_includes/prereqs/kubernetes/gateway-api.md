{% if include.config.gateway_api != false %}

{% assign summary = "Enable the Gateway API" %}
{% if include.config.gateway_api_optional == true %}
{% assign summary = summary | append: " (Optional)" %}
{% endif %}
{% assign icon_url = "/assets/icons/code.svg" %}

{% capture details_content %}

{% assign gw_api_crd_version = "v1.2.0" %}

{% if include.config.gateway_api == "experimental" %}

1. Install the **experimental** Gateway API CRDs before installing {{ site.kic_product_name }}:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/{{ gw_api_crd_version}}/experimental-install.yaml
   ```

   {% else %}

1. Install the Gateway API CRDs before installing {{ site.kic_product_name }}.

   <!-- kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/{{ gw_api_crd_version}}/standard-install.yaml -->

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/{{ gw_api_crd_version}}/standard-install.yaml
   ```

   {% endif %}

1. Create a `Gateway` and `GatewayClass` instance to use.

{% assign gwapi_version = "1.3.0" %}

{% assign allowedRoutes = "All" %}
{% if include.config.gateway_api.allowed_routes %}
{% assign allowedRoutes = include.config.gateway_api.allowed_routes %}
{% endif %}

{% assign controllerName = "" %}
{% if product == 'kic' %}
{% assign controllerName = "konghq.com/kic-gateway-controller" %}
{% endif %}
{% if product == 'operator' %}
{% assign controllerName = "konghq.com/gateway-operator" %}
{% endif %}

{% if controllerName == "" %}
{% raise "k8s controller name was not provided" %}
{% endif %}

```bash
echo "
apiVersion: v1
kind: Namespace
metadata:
  name: kong
---
apiVersion: gateway.networking.k8s.io/{{ gwapi_version }}
kind: GatewayClass
metadata:
  name: kong
  annotations:
    konghq.com/gatewayclass-unmanaged: 'true'

spec:
  controllerName: {{ controllerName }}
---
apiVersion: gateway.networking.k8s.io/{{ gwapi_version }}
kind: Gateway
metadata:
  name: kong
spec:
  gatewayClassName: kong
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
         from: {{ allowedRoutes }}
" | kubectl apply -n kong -f -
```

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}

{% endif %}
