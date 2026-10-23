---
title: Install {{site.mesh_product_name}} and deploy Kong Air
description: Create the Kong Air mesh in {{site.konnect_short_name}}, connect a Kubernetes zone, and deploy the Kong Air demo applications. The other Kong Air scenarios build on this setup.
content_type: how_to
permalink: /mesh/install-kong-mesh-and-deploy-kong-air/
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
tools:
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
    1. Create the `kong-air-mesh` mesh on your {{site.konnect_short_name}}-hosted global control plane with kongctl.
    2. Install a zone control plane on Kubernetes with Helm and connect it to the global control plane as `zone1`.
    3. Deploy the Kong Air demo applications into a namespace with sidecar injection enabled.
faqs:
  - q: How do I authenticate kongctl in CI or another non-interactive environment?
    a: |
      Use a [personal access token](https://cloud.konghq.com/global/account/tokens) instead of `kongctl login`.
      kongctl reads the token from the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable.
      See [Authentication with kongctl](/kongctl/authentication/).
  - q: What if two of my control planes share a name?
    a: |
      Pass `--control-plane-id` instead of `--control-plane-name` to every `kongctl` mesh command.
      See [Choosing a control plane and a mesh](/mesh/cli/#choosing-a-control-plane-and-a-mesh).
  - q: Can I use kongctl with a self-managed global control plane?
    a: |
      Yes. Pass `--control-plane-url` instead of `--control-plane-name`.
      See [Choosing a control plane and a mesh](/mesh/cli/#choosing-a-control-plane-and-a-mesh).
prereqs:
  inline:
    - title: A running Kubernetes cluster
      include_content: md/mesh/v3/prereqs/kubernetes-cluster
    - title: Helm
      include_content: prereqs/helm
    - title: Connect kongctl to your control plane
      include_content: md/mesh/v3/prereqs/kongctl
cleanup:
  inline:
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
related_resources:
  - text: Architecture overview
    url: /mesh/architecture-overview/
  - text: Resource scoping
    url: /mesh/resource-scoping/
next_steps:
  - text: "How-to: Create a security policy"
    url: "/mesh/create-a-security-policy/"
---

Every Kong Air scenario runs on the same foundation:
* A `kong-air-mesh` mesh on a {{site.konnect_short_name}}-hosted global control plane
* One Kubernetes zone named `zone1`, connected to the global control plane
* Three demo applications

In this guide, you build that foundation.

## Create the mesh and connect a Kubernetes zone

The Kong Air zone control plane runs on Kubernetes and connects to the {{site.konnect_short_name}} global control plane.
You create the mesh on the global control plane with [kongctl](/kongctl/), then install the zone control plane with Helm.

1. Create the `kong-air-mesh` mesh on the global control plane:

   ```sh
   kongctl apply mesh --control-plane-name "$MESH_CP" -f - <<'EOF'
   type: Mesh
   name: kong-air-mesh
   EOF
   ```

1. Export your {{site.konnect_short_name}} geographic region and the Kuma Discovery Service (KDS) address that the zone connects to:

   ```sh
   export KONNECT_REGION='us'
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   ```

1. Export the ID of your control plane.
   To print the full IDs, run `kongctl get mesh control-planes --text-id-format full`:

   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```

1. Issue a zone token.
   The zone control plane uses this token to prove its identity when it joins the global control plane:

   ```sh
   kongctl create mesh zone-token \
     --control-plane-name "$MESH_CP" \
     --zone zone1 \
     --valid-for 720h > zone-token
   ```

1. Create the namespace for the zone control plane:

   ```sh
   kubectl create namespace kong-mesh-system
   ```

1. Store the zone token in a Kubernetes secret, so the zone control plane can read it at startup:

   ```sh
   kubectl create secret generic cp-token \
     -n kong-mesh-system \
     --from-file=token=zone-token
   ```

1. Create the Helm values file.
   The `meshes` entry deploys a zone ingress and a zone egress for `kong-air-mesh`.
   For details, see [Deploy proxies for a mesh on Kubernetes](/mesh/mesh-scoped-zone-proxies/#kubernetes):

   ```sh
   cat <<EOF > values.yaml
   kuma:
     controlPlane:
       mode: zone
       zone: zone1
       kdsGlobalAddress: $CONTROL_PLANE_URL
       konnect:
         cpId: $CONTROL_PLANE_ID
       envVars:
         KUMA_DEFAULTS_RESTRICT_OUTBOUND: "false"
       secrets:
         - Env: KUMA_MULTIZONE_ZONE_KDS_AUTH_TOKEN_INLINE
           Secret: cp-token
           Key: token
     meshes:
       - name: kong-air-mesh
         ingress:
           enabled: true
         egress:
           enabled: true
   EOF
   ```

   The values file sets `KUMA_DEFAULTS_RESTRICT_OUTBOUND` to `false`, so the Kong Air mesh starts open on purpose.
   With this setting, sidecars can reach destinations that you haven't declared yet.
   [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) turns `restrictOutbound` on, which is how a production mesh must run.

1. Add the {{site.mesh_product_name}} Helm repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   ```

1. Install the {{site.mesh_product_name}} zone control plane with your values file:

   ```sh
   helm upgrade --install \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh -f values.yaml
   ```

1. Wait for the zone control plane to be ready:

   ```sh
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

1. Deploy the Kong Air demo applications: `passenger-portal`, `check-in-api`, and `flight-control`.
   Each application runs in the `kong-air-production` namespace with its own service account.
   When you add a workload identity in [Create a security policy](/mesh/create-a-security-policy/), each workload gets its own Secure Production Identity Framework for Everyone (SPIFFE) ID:

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
