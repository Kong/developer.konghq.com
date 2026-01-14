---
title: Deploy Konnect Managed Control Plane
description: "Learn how to install Mesh on an existing Kubernetes cluster, and deploy the {{site.mesh_product_name}} demo application."
content_type: how_to
permalink: /mesh/deploy-mesh-on-konnect/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/

products:
  - mesh

tldr:
  q: How do I install {{site.mesh_product_name}} with a {{site.konnect_short_name}} managed Control plane
  a: Install {{site.mesh_product_name}} zone Control plane in your environment and let {{site.konnect_short_name}} take care of the global Control plane.

prereqs:
  inline:
    - title: "Create a {{site.mesh_product_name}} control plane"
      include_content: prereqs/mesh

---


## Install {{site.mesh_product_name}}

{% navtabs "kubernetes" %}
{% navtab "Kubernetes" %}

Install {{site.mesh_product_name}} control plane with Helm:

```sh
kubectl create namespace kong-mesh-system
helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
helm repo update
```

Create the control plane token:

```sh
echo "
  apiVersion: v1
  kind: Secret
  metadata:
    name: cp-token
    namespace: kong-mesh-system
  type: Opaque
  data:
    token: $CONTROL_PLANE_TOKEN
" | kubectl apply -f -
```
{% tip %}

The `CONTROL_PLANE_TOKEN` will be created automatically in {{site.konnect_short_name}}

{% endtip %}

Create the Helm values file:

```yaml
echo "
kuma:
  controlPlane:
    mode: zone
    zone: zone3
    kdsGlobalAddress: $CONTROL_PLANE_URL
    konnect:
      cpId: $CONTROL_PLANE_ID
    secrets:
      - Env: $KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE
        Secret: cp-token
        Key: token
  ingress:
    enabled: true
  egress:
    enabled: true
  " > values.yaml
  ```

{% tip %}
`CONTROL_PLANE_ID` and `CONTROL_PLANE_URL` were created automatically in {{site.konnect_short_name}} and exported as environment variable in the prerequisites section.
{% endtip %}

Install {{site.mesh_product_name}}:

```sh
helm upgrade --install -n kong-mesh-system kong-mesh kong-mesh/kong-mesh -f values.yaml
```
{% endnavtab %}
{% navtab "Universal / VM / Bare metal" %}

Save Control Plane token to a file:
```sh
mkdir -p ~/kuma-cp \
  && echo $CONTROL_PLANE_TOKEN > ~/kuma-cp/cpTokenFile \
  && chmod 600 ~/kuma-cp/cpTokenFile
```

Create Mesh config file:

```yaml
echo "
environment: universal
mode: zone
multizone:
  zone:
    name: zone3
    globalAddress: $CONTROL_PLANE_URL
kmesh:
  multizone:
    zone:
      konnect:
        cpId: $CONTROL_PLANE_ID
experimental:
  kdsDeltaEnabled: true
" > config.yaml
```

{% tip %}
`CONTROL_PLANE_ID` and `CONTROL_PLANE_URL` were created automatically in {{site.konnect_short_name}} and exported as environment variable in the prerequisites section.
{% endtip %}

Download {{site.mesh_product_name}} and connect to the zone:

```sh
curl -L http://developer.konghq.com/mesh/installer.sh | sh - \
  && KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_PATH=~/kuma-cp/cpTokenFile kong-mesh-*/bin/kuma-cp run --config-file config.yaml
```

{% endnavtab %}
{% endnavtabs %}

## Deploy the demo application

To start learning how {{site.mesh_product_name}} works, you can use our simple and secure demo application that consists of two services:

* `demo-app`: A web application that lets you increment a numeric counter. It listens on port `5000`
* `redis`: The data store for the counter

{% mermaid %}
flowchart LR
  demo-app(demo-app :5000)
  redis(redis :6379)
  demo-app --> redis
{% endmermaid %}


{% navtabs "kubernetes" %}
{% navtab "Kubernetes" %}

Deploy the demo application: 

```sh
kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
```


{% endnavtab %}
{% navtab "Universal / VM / Bare metal" %}

The `demo-app` service listens on port 5000. When it starts, it expects to find a zone key in Redis that specifies the name of the data center (or cluster) where the Redis instance is running. This name is displayed in the browser.

The zone key is purely static and arbitrary. Different zone values for different Redis instances let you keep track of which Redis instance stores the counter if you manage routes across different zones, clusters, and clouds.

### Universal Prerequisites

- [Redis installed](https://redis.io/docs/latest/operate/oss_and_stack/install/install-stack)
- [{{site.mesh_product_name}} installed](/mesh)
- [Demo app downloaded from GitHub](https://github.com/kumahq/kuma-counter-demo):

  ```sh
  git clone https://github.com/kumahq/kuma-counter-demo.git
  ```


### Set up

1.  Run `redis` as a daemon on port 26379 and set a default zone name:

    ```sh
    redis-server --port 26379 --daemonize yes
    redis-cli -p 26379 set zone local
    ```

1.  Install and start `demo-app` on the default port 5000:

    ```sh
    npm install --prefix=app/
    npm start --prefix=app/
    ```

### Generate tokens

Create a token for Redis and a token for the app (all valid for 30 days):

```sh
kumactl generate dataplane-token --tag kuma.io/service=redis --valid-for=720h > kuma-token-redis
kumactl generate dataplane-token --tag kuma.io/service=app --valid-for=720h > kuma-token-app
```

{% warning %}
This action requires [authentication](/mesh/authentication-with-the-api-server/#admin-user-token) unless executed against a control-plane running on localhost.
{% endwarning %}

### Create a data plane proxy for each service

For Redis:

```sh
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=kuma-token-redis \
  --dataplane="
  type: Dataplane
  mesh: default
  name: redis
  networking: 
    address: 127.0.0.1
    inbound: 
      - port: 16379
        servicePort: 26379
        serviceAddress: 127.0.0.1
        tags: 
          kuma.io/service: redis
          kuma.io/protocol: tcp
    admin:
      port: 9901"
```

And for the demo app:

```sh
kuma-dp run \
  --cp-address=https://localhost:5678/ \
  --dns-enabled=false \
  --dataplane-token-file=kuma-token-app \
  --dataplane="
  type: Dataplane
  mesh: default
  name: app
  networking: 
    address: 127.0.0.1
    outbound:
      - port: 6379
        tags:
          kuma.io/service: redis
    inbound: 
      - port: 15000
        servicePort: 5000
        serviceAddress: 127.0.0.1
        tags: 
          kuma.io/service: app
          kuma.io/protocol: http
    admin:
      port: 9902"
```


{% endnavtab %}
{% endnavtabs %}

{:.info}
When using the {{site.konnect_short_name}} managed control plane, all changes to the Mesh must be applied using `kumactl`.  You can configure `kumactl` connectivity by clicking on **Actions** from the Mesh overview in [{{site.konnect_short_name}}](https://cloud.konghq.com/us/mesh-manager).


## Forward ports

Port-forward the service to the namespace on port `5000`:

```sh
kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
```

## Validate

Navigate to [`127.0.0.1:5000/`](http://127.0.0.1:5000/) in your web browser and increment the counter.

Now that you have you workloads up and running, we can secure them with Mutual TLS.

## Introduce zero-trust security

By default, service-to-service traffic in the mesh is not encrypted. You can change this in {{site.mesh_product_name}} by enabling the [Mutual TLS](/mesh/policies/mutual-tls/) (mTLS) policy, which provisions a dynamic Certificate Authority (CA) on the `default` Mesh. This CA automatically issues TLS certificates to all dataplanes.

To enable mTLS using a built-in CA:

{% warning %}
Do not enable mTLS in an environment with existing workloads until you define a `MeshTrafficPermission` policy. 
Without it, service-to-service communication will be blocked.
{% endwarning %}

```sh
cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
EOF
```

After enabling mTLS, service communication will be denied by default. To restore connectivity, apply a fully permissive [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy:

```sh
cat <<EOF | kumactl apply -f -
type: MeshTrafficPermission
name: allow-all
mesh: default
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow
EOF
```