{% on_prem %}
content: |
  Create the `kong` namespace:

  ```sh
  kubectl create namespace kong
  ```
  {: data-test-prereq="block" }
{% endon_prem %}

{% konnect %}
content: |
  Create the `kong` namespace:

  ```sh
  kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
  ```
  {: data-test-prereq="block" }
{% endkonnect %}

Create the `GatewayConfiguration`, `GatewayClass`, and `Gateway` resources with basic configuration:

{% if page.prereqs.operator.konnect.auth %}
{% konnect %}
content: |
  Setting `spec.konnect.authRef` attaches the data plane to {{site.konnect_short_name}}, which manages its configuration:

  ```sh
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: gateway-configuration
    namespace: kong
  spec:
    konnect:
      authRef:
        name: konnect-api-auth
        namespace: kong
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
    annotations:
      gateway-operator.konghq.com/static-naming: "true"
  spec:
    gatewayClassName: gateway-class
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
  {: data-test-prereq="block" }

  The `gateway-operator.konghq.com/static-naming: "true"` annotation gives the resources {{ site.operator_product_name }} generates for the `Gateway` static, predictable names: the `KonnectGatewayControlPlane` it creates for the `Gateway` is named after the `Gateway`, in this case `kong`. You can reference that control plane from other resources before it exists, and its name in {{site.konnect_short_name}} is derived from the `Gateway` name.
{% endkonnect %}
{% endif %}

{% on_prem %}
content: |
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
  {: data-test-prereq="block" }
{% endon_prem %}
