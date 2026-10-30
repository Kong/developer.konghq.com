---
title: Deploy data planes on an IPv6-only cluster
description: "Run {{ site.operator_product_name }} data planes on an IPv6-only Kubernetes cluster and send traffic to them over IPv6."
content_type: how_to

permalink: /operator/dataplanes/how-to/ipv6/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem
  - konnect

min_version:
  operator: '2.4'

related_resources:
  - text: Deploy data planes on a dual-stack cluster
    url: /operator/dataplanes/how-to/dual-stack/
  - text: Kubernetes IPv4/IPv6 dual-stack
    url: https://kubernetes.io/docs/concepts/services-networking/dual-stack/

tldr:
  q: How do I run a data plane on an IPv6-only Kubernetes cluster?
  a: Install {{ site.operator_product_name }} with the `--ip-family=ipv6` argument, then create a Gateway. The data plane's listeners bind to IPv6, and its ingress Service is a single-stack IPv6 Service.

prereqs:
  show_works_on: true
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: IPv6-only Kubernetes cluster
      include_content: prereqs/operator/ipv6-cluster
      icon_url: /assets/icons/kubernetes.svg

faqs:
  - q: How does {{ site.operator_product_name }} detect the cluster's IP family?
    a: |
      By default, the `--ip-family` argument is set to `auto`.
      With `auto`, {{ site.operator_product_name }} reads the IP family of the `default/kubernetes` Service at startup.
      If detection fails, {{ site.operator_product_name }} exits with an error.
      Setting `--ip-family=ipv6` skips detection, so {{ site.operator_product_name }} starts even when the `default/kubernetes` Service can't be read.
  - q: Which data plane listeners use {{ site.operator_product_name }}'s IP family?
    a: |
      {{ site.operator_product_name }} binds the data plane's Kong proxy, admin, status, and stream listeners to the IP family set by `--ip-family`.
      On an IPv6-only cluster, all of these listeners bind to IPv6 addresses.
  - q: How do I expose a data plane outside the cluster over IPv6?
    a: |
      To expose a data plane outside the cluster over IPv6, set the ingress Service `type` in the `GatewayConfiguration` to `LoadBalancer`:

      ```yaml
      spec:
        dataPlaneOptions:
          network:
            services:
              ingress:
                type: LoadBalancer
      ```

      The Gateway is programmed only after the cluster assigns an external address to the load balancer.
      Local clusters such as kind don't assign load balancer addresses by default.
  - q: How do I expose a data plane over IPv6 on AWS EKS?
    a: |
      On AWS EKS, the in-tree cloud provider only provisions IPv4-only Network Load Balancers.
      To expose a data plane externally on an IPv6-only EKS cluster, install the [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html).
      Then, set the ingress Service type to `LoadBalancer` and add the following annotations to the ingress Service in your `GatewayConfiguration` so the AWS Load Balancer Controller provisions a dual-stack Network Load Balancer:

      ```yaml
      spec:
        dataPlaneOptions:
          network:
            services:
              ingress:
                type: LoadBalancer
                annotations:
                  service.beta.kubernetes.io/aws-load-balancer-type: external
                  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
                  service.beta.kubernetes.io/aws-load-balancer-ip-address-type: dualstack
                  service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
      ```
  - q: Can I run data planes on a dual-stack cluster?
    a: |
      Yes. {{ site.operator_product_name }} supports dual-stack clusters as a tech preview.
      See [Deploy data planes on a dual-stack cluster](/operator/dataplanes/how-to/dual-stack/).

---

{% include /k8s/kong-namespace.md %}

## Install {{ site.operator_product_name }}

Add the Kong Helm charts and update them:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

Install {{ site.operator_product_name }} with the `--ip-family=ipv6` argument.
With this argument, {{ site.operator_product_name }} binds the data plane's listeners to IPv6 and creates IPv6 ingress Services.
Helm passes the argument to {{ site.operator_product_name }} through the chart's `args` value:

{% konnect %}
content: |
  ```bash
  helm upgrade --install kong-operator kong/kong-operator -n kong-system \
    --create-namespace \
    --set image.tag={{ site.data.operator_latest.release }} \
    --set env.ENABLE_CONTROLLER_KONNECT=true \
    --set 'args[0]=--ip-family=ipv6'
  ```
{% endkonnect %}

{% on_prem %}
content: |
  ```bash
  helm upgrade --install kong-operator kong/kong-operator -n kong-system \
    --create-namespace \
    --set image.tag={{ site.data.operator_latest.release }} \
    --set 'args[0]=--ip-family=ipv6'
  ```
{% endon_prem %}

{% include operator/kong-license.md %}

{% include operator/konnect-auth.md %}

## Create a Gateway

Create a `GatewayConfiguration`, a `GatewayClass`, and a `Gateway`:

{% konnect %}
content: |
  ```bash
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: ipv6
    namespace: kong
  spec:
    konnect:
      authRef:
        name: konnect-api-auth
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy
      network:
        services:
          ingress:
            type: ClusterIP
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: ipv6
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: ipv6
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
    gatewayClassName: ipv6
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
{% endkonnect %}

{% on_prem %}
content: |
  ```bash
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: ipv6
    namespace: kong
  spec:
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy
      network:
        services:
          ingress:
            type: ClusterIP
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: ipv6
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: ipv6
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong
    namespace: kong
  spec:
    gatewayClassName: ipv6
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
{% endon_prem %}

Because the IP family is set to `ipv6`, {{ site.operator_product_name }} binds the data plane's listeners to IPv6 and creates a single-stack IPv6 ingress Service without any IP family settings in the `GatewayConfiguration`.
The `GatewayConfiguration` sets the ingress Service type to `ClusterIP`, so the Gateway is programmed without waiting for a load balancer address

Wait for the Gateway to be programmed:

```bash
kubectl wait --for=condition=programmed gateway/kong -n kong --timeout=300s
```

## Validate

Export the name of the data plane's ingress Service:

```bash
export INGRESS_SERVICE=$(kubectl get svc -n kong \
  -l gateway-operator.konghq.com/dataplane-service-type=ingress \
  -o jsonpath='{.items[0].metadata.name}')
```

Check the IP families of the ingress Service:

```bash
kubectl get svc $INGRESS_SERVICE -n kong \
  -o jsonpath='{.spec.ipFamilies}{"\t"}{.spec.ipFamilyPolicy}{"\n"}'
```

The ingress Service is a single-stack IPv6 Service:

```
["IPv6"]	SingleStack
```
{:.no-copy-code}

Export the ingress Service's IPv6 cluster IP:

```bash
export PROXY_IPV6=$(kubectl get svc $INGRESS_SERVICE -n kong -o jsonpath='{.spec.clusterIP}')
```

Send a request to the proxy over IPv6 from a temporary Pod in the cluster:

```bash
kubectl run curl -n kong --rm -it --restart=Never --image=curlimages/curl -- \
  curl -s -w '\nremote_ip: %{remote_ip}\n' "http://[$PROXY_IPV6]"
```

The output includes the response from {{ site.base_gateway }} and the address that curl connected to:

```
{
  "message":"no Route matched with those values",
  "request_id":"780b0503694882228829e12c85c46462"
}
remote_ip: fd00:10:96::64bb
```
{:.no-copy-code}

{{ site.base_gateway }} returns a `no Route matched` error because the Gateway doesn't have any Routes yet.
The `remote_ip` value is a colon-separated hexadecimal address, which means the request used IPv6.
This response confirms that the data plane accepts connections over IPv6.
