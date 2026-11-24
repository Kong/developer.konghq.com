---
title: Install {{site.mesh_product_name}} and deploy Kong Air
description: Create the Kong Air mesh in {{site.konnect_short_name}}, connect a Kubernetes zone, and deploy the Kong Air demo applications. The other Kong Air scenarios build on this setup.
content_type: how_to
permalink: /mesh/install-kong-mesh-and-deploy-kong-air/
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
tools:
  - konnect-api
  - kongctl
products:
  - mesh
works_on:
  - konnect
tags:
  - install
  - kubernetes
  - helm
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 1
tldr:
  q: How do I set up {{site.mesh_product_name}} for the Kong Air scenarios?
  a: |
    1. Create a global control plane in {{site.konnect_short_name}}.
    2. Create the `kong-air-mesh` mesh on the global control plane with kongctl.
    3. Install a zone control plane on Kubernetes with Helm and connect it to the global control plane as `zone1`.
    4. Deploy the Kong Air demo applications into a namespace with sidecar injection enabled.
faqs:
  - q: How do I avoid passing `--pat` to every kongctl command?
    a: |
      Run `kongctl login` once, or export your token in the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable.
      See [Authentication with kongctl](/kongctl/authentication/).
  - q: Can I use kongctl with a self-managed global control plane?
    a: |
      Yes. Pass `--control-plane-url` instead of `--control-plane-id`, `--region`, `--base-url`, and `--pat`.
      See [Choosing a control plane and a mesh](/mesh/cli/#choosing-a-control-plane-and-a-mesh).
prereqs:
  inline:
    - title: A minikube cluster
      include_content: md/mesh/v3/prereqs/kubernetes-cluster
    - title: Helm
      include_content: prereqs/helm
related_resources:
  - text: Architecture overview
    url: /mesh/architecture-overview/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Introduction to Kong Air
    url: /mesh/scenarios/introduction-kong-air/
  - text: Concepts
    url: /mesh/concepts/
---

Every Kong Air scenario runs on the same foundation:
* A `kong-air-mesh` mesh on a {{site.konnect_short_name}}-hosted global control plane
* One Kubernetes zone named `zone1`, connected to the global control plane
* Three demo applications

In this guide, you build that foundation.

To learn more about what this guide does, read the following reference pages:

* [Introduction to Kong Air](/mesh/scenarios/introduction-kong-air/): the context for this scenario
* [Architecture overview](/mesh/architecture-overview/): how the global and zone control planes connect
* [Resource scoping](/mesh/resource-scoping/): which control plane owns each resource

## Create a working directory

Create a directory for the files that the series creates, such as Helm values files, and change to it.
Run the commands of every guide in the series from this directory:

```sh
mkdir kong-air-scenarios && cd kong-air-scenarios
```

## Create a global control plane in {{site.konnect_short_name}}

{% include md/mesh/v3/how-tos/create-global-control-plane.md name='kong-air-cp' %}

## Give the zone credentials to connect

{% include md/mesh/v3/how-tos/give-zone-credentials.md zone='zone1' %}

## Create the mesh and connect a Kubernetes zone

The Kong Air zone control plane runs on Kubernetes and connects to the {{site.konnect_short_name}} global control plane.
You create the mesh on the global control plane with [kongctl](/kongctl/), then install the zone control plane with Helm.

1. Create the `kong-air-mesh` mesh on the global control plane:

   ```sh
   kongctl apply mesh -f - --control-plane-id "$CONTROL_PLANE_ID" \
     --base-url "https://$KONNECT_REGION.api.konghq.com" --pat "$KONNECT_TOKEN" <<'EOF'
   type: Mesh
   name: kong-air-mesh
   EOF
   ```

1. Export the Kuma Discovery Service (KDS) address that the zone connects to:

   ```sh
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   ```

1. Create the namespace for the zone control plane:

   ```sh
   kubectl create namespace kong-mesh-system
   ```

1. Store the system account token in the `token` key of a Kubernetes secret named `cp-token`.
   The zone control plane uses this token to prove its identity when it joins the global control plane:

   ```sh
   kubectl create secret generic cp-token \
     -n kong-mesh-system \
     --from-literal=token="$CONTROL_PLANE_TOKEN"
   ```

1. Create the Helm values file.
   The `meshes` entry deploys a zone ingress and a zone egress for `kong-air-mesh`:

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone1
       kdsGlobalAddress: $CONTROL_PLANE_URL
       konnect:
         cpId: $CONTROL_PLANE_ID
       zoneToken:
         secretName: cp-token
         key: token
       envVars:
         KUMA_DEFAULTS_RESTRICT_OUTBOUND: "false"
     meshes:
       - name: kong-air-mesh
         ingress:
           enabled: true
           service:
             type: NodePort
         egress:
           enabled: true
   EOF
   ```

   The ingress Service uses the `NodePort` type, because a local cluster such as minikube doesn't assign an address to a `LoadBalancer` Service.
   The zone control plane publishes the node IP and port in a `MeshZoneAddress`, so other zones can reach the ingress.
   On a cloud cluster, you can use a `LoadBalancer` Service instead.

   The `zoneToken` entry mounts the `cp-token` secret into the zone control plane as a file.
   The zone control plane reads the token on every KDS connection, so it picks up a rotated token without a restart.

   The values file sets `KUMA_DEFAULTS_RESTRICT_OUTBOUND` to `false`, so the Kong Air mesh starts open on purpose.
   With this setting, sidecars can reach destinations that you haven't declared yet.
   [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) turns `restrictOutbound` on, which is how a production mesh must run.

1. Add the {{site.mesh_product_name}} Helm repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   ```

1. Install the {{site.mesh_product_name}} zone control plane with your values file and wait for it to be ready:

   ```sh
   helm upgrade --install \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh -f values.yaml
   kubectl wait -n kong-mesh-system --for=condition=ready pod \
     --selector=app=kong-mesh-control-plane --timeout=90s
   ```

1. Confirm that the zone joined the global control plane and received the mesh:

   ```sh
   kubectl get meshes
   ```

   The output lists `kong-air-mesh` after the global control plane sends the mesh to the zone over KDS.
   This confirms that the zone is connected.

## Deploy Kong Air

1. Deploy the Kong Air demo applications: `passenger-portal`, `check-in-api`, and `flight-control`:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: v1
   kind: Namespace
   metadata:
     name: kong-air-production
     labels:
       kuma.io/sidecar-injection: enabled
       kuma.io/mesh: kong-air-mesh
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: passenger-portal
     namespace: kong-air-production
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: check-in-api
     namespace: kong-air-production
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: flight-control
     namespace: kong-air-production
   ---
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: nginx-passthrough
     namespace: kong-air-production
   data:
     default.conf: |
       server {
           listen 8080;
           location / {
               add_header Content-Type text/plain;
               return 200 "$hostname\n";
           }
           location /health {
               add_header Content-Type text/plain;
               return 200 "ok\n";
           }
           location = /manifest.bin {
               root /tmp;
           }
       }
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: passenger-portal
     namespace: kong-air-production
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: passenger-portal
         version: v1
     template:
       metadata:
         labels:
           app: passenger-portal
           version: v1
       spec:
         serviceAccountName: passenger-portal
         containers:
           - name: passenger-portal
             image: nginx:alpine
             ports:
               - containerPort: 8080
             volumeMounts:
               - name: nginx-config
                 mountPath: /etc/nginx/conf.d
             readinessProbe:
               httpGet:
                 path: /health
                 port: 8080
               initialDelaySeconds: 5
               periodSeconds: 5
         volumes:
           - name: nginx-config
             configMap:
               name: nginx-passthrough
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: passenger-portal
     namespace: kong-air-production
   spec:
     selector:
       app: passenger-portal
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: check-in-api
     namespace: kong-air-production
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: check-in-api
         version: v1
     template:
       metadata:
         labels:
           app: check-in-api
           version: v1
       spec:
         serviceAccountName: check-in-api
         containers:
           - name: check-in-api
             image: nginx:alpine
             ports:
               - containerPort: 8080
             volumeMounts:
               - name: nginx-config
                 mountPath: /etc/nginx/conf.d
             readinessProbe:
               httpGet:
                 path: /health
                 port: 8080
               initialDelaySeconds: 5
               periodSeconds: 5
         volumes:
           - name: nginx-config
             configMap:
               name: nginx-passthrough
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: check-in-api
     namespace: kong-air-production
   spec:
     selector:
       app: check-in-api
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: flight-control
     namespace: kong-air-production
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: flight-control
         version: v1
     template:
       metadata:
         labels:
           app: flight-control
           version: v1
       spec:
         serviceAccountName: flight-control
         containers:
           - name: flight-control
             image: nginx:alpine
             ports:
               - containerPort: 8080
             volumeMounts:
               - name: nginx-config
                 mountPath: /etc/nginx/conf.d
             readinessProbe:
               httpGet:
                 path: /health
                 port: 8080
               initialDelaySeconds: 5
               periodSeconds: 5
         volumes:
           - name: nginx-config
             configMap:
               name: nginx-passthrough
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: flight-control
     namespace: kong-air-production
   spec:
     selector:
       app: flight-control
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
   EOF
   ```
   {:.collapsible}

   Each application is an nginx server that returns its Pod name on `/` and `ok` on `/health`.
   The `/manifest.bin` location serves a file that [Validate resilience with fault injection](/mesh/validate-resilience-with-fault-injection/) creates to show a bandwidth limit.
   Each application runs in the `kong-air-production` namespace with its own service account.

1. Wait for the Kong Air deployments to be available:

   ```sh
   kubectl wait -n kong-air-production --for=condition=available --timeout=120s deployment --all
   ```

## Validate

Confirm that each Kong Air pod is running with a {{site.mesh_product_name}} sidecar:

```sh
kubectl get pods -n kong-air-production
```

Every pod reports `2/2` in the `READY` column.
One container runs the application, and the other runs the sidecar proxy.
