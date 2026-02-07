---
title: Route traffic with a Kubernetes Ingress resource
description: "Configure {{ site.operator_product_name }} to manage traditional Kubernetes Ingress resources."
content_type: how_to

permalink: /operator/dataplanes/how-to/handle-ingress/
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

tldr:
  q: How do I configure {{ site.operator_product_name }} to handle Kubernetes Ingress resources?
  a: Set the `spec.ingressClass` field in the `ControlPlane` resource to match your `Ingress` resource's `spec.ingressClassName`.

---

While the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) is the preferred mechanism for configuring inbound routing, {{ site.operator_product_name }} also supports the [Kubernetes Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/).

{% include /k8s/kong-namespace.md %}

## Create the GatewayConfiguration

Create a `GatewayConfiguration` resource to customize the deployment options for your data plane and control plane:

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: kong-ingress-config
  namespace: kong
spec:
  dataPlaneOptions:
    deployment:
      replicas: 1
' | kubectl apply -f -
```

## Create the DataPlane

Create a `DataPlane` resource to define the {{ site.base_gateway }} deployment:

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: kong-ingress-dp
  namespace: kong
spec:
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
' | kubectl apply -f -
```

## Create the ControlPlane

Create a `ControlPlane` resource to define the controller that will manage the `DataPlane`. 
To enable `Ingress` support, you must specify the `spec.ingressClass` field:

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v2beta1
kind: ControlPlane
metadata:
  name: kong-ingress-cp
  namespace: kong
spec:
  dataplane:
    type: ref
    ref:
      name: kong-ingress-dp
  ingressClass: kong
' | kubectl apply -f -
```

## Create the echo Service

Run the following command to create a sample echo Service:
```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Create the Ingress

Create an `Ingress` resource that points to the echo service and specify the `spec.ingressClass` configured in the [`ControlPlane` resource](#create-the-controlplane) in the `spec;ingressClassName` field:

```yaml
echo '
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: kong
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo
            port:
              number: 1027
' | kubectl apply -f -
```

## Validate

1. Check that the resources have been created:

   ```bash
   kubectl get controlplane,dataplane,ingress -n kong
   ```

1. Get the external IP of the `DataPlane` service:

   ```bash
   export PROXY_IP=$(kubectl get svc -n kong -l app=kong-ingress-dp,gateway-operator.konghq.com/dataplane-service-type=ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
   ```

1. Send a request to the Ingress:

   ```sh
   curl -i http://$PROXY_IP/
   ```
