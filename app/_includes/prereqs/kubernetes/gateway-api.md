{% if include.gateway_api != false %}

{% assign summary = "Enable the Gateway API" %}
{% assign icon_url = "/assets/icons/code.svg" %}

{% capture details_content %}

{% assign gw_api_crd_version = "v1.2.0" %}

### Install the Gateway APIs

{% if include.config.gateway_api == "experimental" %}

1. Install the experimental Gateway API CRDs before installing {{ site.kic_product_name }}.

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

{% assign gwapi_version = "v1" %}

```bash
echo "
apiVersion: v1
kind: Namespace
metadata:
  name: kong-docs-demo
---
apiVersion: gateway.networking.k8s.io/{{ gwapi_version }}
kind: GatewayClass
metadata:
  name: kong
  annotations:
    konghq.com/gatewayclass-unmanaged: 'true'

spec:
  controllerName: konghq.com/kic-gateway-controller
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
         from: All
" | kubectl apply -n kong-docs-demo -f -
```

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}

{% endif %}
