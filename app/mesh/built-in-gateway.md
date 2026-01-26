---
title: Built-in gateways in {{site.mesh_product_name}}
description: Learn about built-in gateways with {{site.mesh_product_name}} using MeshGateway, MeshGatewayInstance, and Dataplane resources in both Kubernetes and Universal environments.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

min_version:
  mesh: '2.7'

related_resources:
  - text: Set up a built-in gateway
    url: /how-to/set-up-a-built-in-mesh-gateway/
  - text: Configuring built-in listeners
    url: /mesh/gateway-listeners/
  - text: Configuring built-in routes
    url: /mesh/gateway-routes/
  - text: Delegated gateways
    url: /mesh/ingress-gateway-delegated/
  - text: Kubernetes Gateway API
    url: /mesh/kubernetes-gateway-api/

---

In {{site.mesh_product_name}}, gateways allow you to manage [ingress traffic](/mesh/ingress/) between a client and the Services in your meshes. You can either use a [delegated gateway](/mesh/ingress-gateway-delegated/), such as {{site.base_gateway}}, or a built-in gateway. 

{:.info}
> In a Kubernetes environment, you can choose between the built-in {{site.mesh_product_name}} gateway, or the built-in gateway provided by the Kubernetes Gateway API.
> 
> This page focuses on the built-in {{site.mesh_product_name}} gateway. For more information about the Kubernetes built-in gateway, see [Kubernetes built-in gateways with {{site.mesh_product_name}}](/mesh/kubernetes-gateway-api/).

You can set up a built-in gateway using a combination of the [`MeshGateway`](/mesh/gateway-listeners/), [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) and [`MeshTCPRoute`](/mesh/policies/meshtcproute/) resources. Each gateway uses Envoy instances represented by `Dataplane` resources configured as built-in. You can then use {{ site.mesh_product_name }} policies to configure your gateway.

To learn how to create a built-in gateway in a Kubernetes environment, see [Set up a built-in gateway](/how-to/set-up-a-built-in-mesh-gateway/).

## Deploying gateways

The process for deploying built-in gateways is different depending on whether you're running in [Kubernetes](/mesh/kubernetes/) or [Universal](/mesh/universal/) mode.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

To manage gateway instances on Kubernetes, {{site.mesh_product_name}} provides a [`MeshGatewayInstance`](/mesh/gateway-pods-k8s/) CRD.
Here's a `MeshGatewayInstance` configuration example:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: edge-gateway
  namespace: default
spec:
  replicas: 1
  serviceType: LoadBalancer
```

This resource launches the `kuma-dp` binary in your cluster.

{:.warning}
> If you're running a multi-zone {{ site.mesh_product_name }}, the `MeshGatewayInstance` needs to be created in a specific zone, not in the global cluster.
> For more information, see the [Multi-zone](#multi-zone) section.

The `MeshGatewayInstance` resource manages a Kubernetes `Deployment` and `Service` that can provide Service capacity for the `MeshGateway`.

{:.warning}
> In previous versions of {{site.mesh_product_name}}, setting the `kuma.io/service` tag directly in a `MeshGatewayInstance` resource was used to identify the Service. However, this practice is deprecated and no longer recommended for security reasons since {{site.mesh_product_name}} version 2.7.0.

> We've automatically switched to generating the Service name for you based on your `MeshGatewayInstance` resource name and namespace. The Service name is generated using the following format: `{name}_{namespace}_svc`.


See [the `MeshGatewayInstance` docs](/mesh/gateway-pods-k8s/) for more information.
{% endnavtab %}
{% navtab "Universal" %}

To manage gateway instances on Universal, you must create a `Dataplane` object for your gateway:

```yaml
type: Dataplane
mesh: default
name: gateway-instance-1
networking:
  address: 127.0.0.1
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
```

Note that this gateway has an identifying `kuma.io/service` tag.

Then, run `kuma-dp` with the `Dataplane` configuration file and a [token](/mesh/dp-auth/#data-plane-proxy-token):

```shell
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=$TOKEN
  --dataplane-file=$DATAPLANE_FILE
```

{% endnavtab %}
{% navtab "Kubernetes without MeshGatewayInstance" %}

Using `MeshGatewayInstance` is highly recommended to manage built-in gateways with Kubernetes.
If for any reason you are unable to use `MeshGatewayInstance`, you can manually create a `Deployment` and `Service` to manage `kuma-dp` instances and forward traffic to them.
Keep in mind however, that you'll need to keep the listeners of your `MeshGateway` in sync with your `Service`.

{:.warning}
> The following example uses resources created by a `MeshGatewayInstance` with version 2.6.2, but remember to create a `MeshGatewayInstance` for your version to configure as much as you can and use it as a basis for your self-managed resources.

Here's an example `MeshGateway` spec:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
spec:
  conf:
    listeners:
    - port: 80
      protocol: HTTP
  selectors:
  - match:
      kuma.io/service: demo-app-gateway
```

The `Service` will forward traffic to the `kuma-dp` configured in the next step. Its `ports` need to be in sync with the `MeshGateway` resource's `listeners`:

```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kuma.io/gateway: builtin
  name: demo-app-gateway
  namespace: kuma-demo
spec:
  ports:
  - name: "80"
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: demo-app-gateway
```

The `selector` should match the `Pod` template created in the next step.

The `Deployment` will manage running `kuma-dp` instances that are configured to serve traffic for your `MeshGateway`.

You'll need to change:
* The `kuma.io/tags` annotation: It must match the `MeshGateway` `selectors`.
* The `KUMA_CONTROL_PLANE_CA_CERT` environment variable: You can retrieve the value with `kubectl get secret {{site.mesh_product_name_path}}-tls-cert -n {{site.mesh_namespace}} -o=jsonpath='{.data.ca\.crt}' | base64 -d`.
* The `containers[0].image` field: It should be the version of {{site.mesh_product_name}} you're using.

Make sure that the `containers[0].resources` value is appropriate for your use case.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  selector:
    matchLabels:
      app: demo-app-gateway
  template:
    metadata:
      annotations:
        kuma.io/gateway: builtin
        kuma.io/mesh: default
        kuma.io/tags: '{"kuma.io/service":"demo-app_gateway"}'
      creationTimestamp: null
      labels:
        app: demo-app-gateway
        kuma.io/sidecar-injection: disabled
    spec:
      containers:
      - args:
        - run
        - --log-level=info
        - --concurrency=2
        env:
        - name: INSTANCE_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: KUMA_CONTROL_PLANE_CA_CERT
          value: |
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
        - name: KUMA_CONTROL_PLANE_URL
          value: https://{{site.mesh_cp_name}}.{{site.mesh_namespace}}:5678
        - name: KUMA_DATAPLANE_DRAIN_TIME
          value: 30s
        - name: KUMA_DATAPLANE_MESH
          value: default
        - name: KUMA_DATAPLANE_RUNTIME_TOKEN_PATH
          value: /var/run/secrets/kubernetes.io/serviceaccount/token
        - name: KUMA_DNS_CORE_DNS_BINARY_PATH
          value: coredns
        - name: KUMA_DNS_CORE_DNS_EMPTY_PORT
          value: "15054"
        - name: KUMA_DNS_CORE_DNS_PORT
          value: "15053"
        - name: KUMA_DNS_ENABLED
          value: "true"
        - name: KUMA_DNS_ENABLE_LOGGING
          value: "false"
        - name: KUMA_DNS_ENVOY_DNS_PORT
          value: "15055"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: KUMA_DATAPLANE_RESOURCES_MAX_MEMORY_BYTES
          valueFrom:
            resourceFieldRef:
              containerName: kuma-gateway
              divisor: "0"
              resource: limits.memory
        image: docker.io/{{ site.mesh_docker_org }}/kuma-dp:2.6.2
        livenessProbe:
          failureThreshold: 12
          httpGet:
            path: /ready
            port: 9901
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        name: kuma-gateway
        readinessProbe:
          failureThreshold: 12
          httpGet:
            path: /ready
            port: 9901
            scheme: HTTP
          initialDelaySeconds: 1
          periodSeconds: 5
          successThreshold: 1
          timeoutSeconds: 3
        resources:
          limits:
            cpu: "1"
            ephemeral-storage: 1G
            memory: 512Mi
          requests:
            cpu: 50m
            ephemeral-storage: 50M
            memory: 64Mi
        securityContext:
          allowPrivilegeEscalation: false
          runAsGroup: 5678
          runAsUser: 5678
        volumeMounts:
        - mountPath: /tmp
          name: tmp
      securityContext:
        sysctls:
        - name: net.ipv4.ip_unprivileged_port_start
          value: "0"
      volumes:
      - emptyDir: {}
        name: tmp
```

{% endnavtab %}
{% endnavtabs %}

{:.info}
> {{site.mesh_product_name}} gateways are configured with the [Envoy best practices for edge proxies](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge).


## Multi-zone

In a multi-zone deployment, the {{site.mesh_product_name}} gateway resource types `MeshGateway`, [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) and [`MeshTCPRoute`](/mesh/policies/meshtcproute/) are synced across zones by the {{site.mesh_product_name}} control plane.
Follow existing {{site.mesh_product_name}} practice and create any {{site.mesh_product_name}} gateway resources in the global control plane.
Once these resources exist, you can provision serving capacity in the zones where it's needed by deploying built-in gateway `Dataplane` resources (in Universal zones) or `MeshGatewayInstances` (in Kubernetes zones).

For more information, see [Multi-zone deployment](/mesh/mesh-multizone-service-deployment/).