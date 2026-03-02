{% on_prem %}
content: |
  Create the `kong` namespace:

  ```sh
  kubectl create namespace kong
  ```
{% endon_prem %}

Create the `GatewayConfiguration`, `GatewayClass`, and `Gateway` resources with basic configuration:

```sh
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: gateway-configuration
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
              name: proxy
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: gateway-class
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: gateway-class
  listeners:
    - name: http
      port: 80
      protocol: HTTP' | kubectl apply -f -
```