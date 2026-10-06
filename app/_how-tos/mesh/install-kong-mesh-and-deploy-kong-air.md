---
title: Install {{site.mesh_product_name}} and deploy Kong Air
description: Create the Kong Air mesh in {{site.konnect_short_name}}, connect a Kubernetes zone, and deploy the Kong Air demo applications that the rest of the scenarios build on.
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
      Use a [personal access token](https://cloud.konghq.com/global/account/tokens) instead of `kongctl login`. kongctl reads it from the `KONGCTL_DEFAULT_KONNECT_PAT` environment variable. See [Authentication with kongctl](/kongctl/authentication/).
  - q: What if two of my control planes share a name?
    a: |
      Pass `--control-plane-id` instead of `--control-plane-name` to every `kongctl` mesh command. `kongctl get mesh control-planes --text-id-format full` prints the full identifiers.
  - q: Can I use kongctl with a self-managed global control plane?
    a: |
      Yes. Skip the {{site.konnect_short_name}} steps and pass `--control-plane-url` with the control plane's API address instead of `--control-plane-name`, adding `--control-plane-token` if the API requires authentication.
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

Every Kong Air scenario runs against the same foundation: a `kong-air-mesh` mesh on a {{site.konnect_short_name}}-hosted global control plane, one connected Kubernetes zone named `zone1`, and three demo applications. This guide builds that foundation.

## Create the mesh and connect a Kubernetes zone

Create the `Mesh` resource on the {{site.konnect_short_name}} global control plane with [kongctl](/kongctl/):

1. Create the `kong-air-mesh` mesh on the global control plane:

   ```sh
   kongctl apply mesh --control-plane-name "$MESH_CP" -f - <<'EOF'
   type: Mesh
   name: kong-air-mesh
   EOF
   ```

1. Export your {{site.konnect_short_name}} geographic region and the KDS address your zone connects to:

   ```sh
   export KONNECT_REGION='us'
   export CONTROL_PLANE_URL="grpcs://$KONNECT_REGION.mesh.sync.konghq.com:443"
   ```

1. Export the identifier of your control plane. To print identifiers in full, run `kongctl get mesh control-planes --text-id-format full`:

   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```

1. Issue a zone token, which is how the zone control plane proves its identity when it joins the global control plane:

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

1. Store the token in a Kubernetes secret:

   ```sh
   kubectl create secret generic cp-token \
     -n kong-mesh-system \
     --from-file=token=zone-token
   ```

1. Create the Helm values file. The `meshes` list tells the zone control plane which meshes to deploy zone ingress and egress listeners for:

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

   `KUMA_DEFAULTS_RESTRICT_OUTBOUND` is set to `false` so that the mesh starts open for testing purposes. [Prepare the mesh for production](/mesh/prepare-the-mesh-for-production/) turns the setting back on, which is the state a production mesh should run in.

1. Add the {{site.mesh_product_name}} Helm repository:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   ```

1. Install {{site.mesh_product_name}}:

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

1. Confirm that the zone joined the global control plane and that the mesh synced down:

   ```sh
   kubectl get meshes
   ```

   `kong-air-mesh` appears in the output once KDS has delivered it, which proves the zone is connected.

## Deploy Kong Air

1. Deploy the Kong Air demo applications. The `passenger-portal`, `check-in-api`, and `flight-control` services each run in the `kong-air-production` namespace with their own service account, so every workload receives a distinct SPIFFE identity:

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

1. Wait for the resources to be ready:

   ```sh
   kubectl wait -n kong-air-production --for=condition=available --timeout=120s deployment --all
   ```

## Validate

Confirm that each Kong Air pod is running with a {{site.mesh_product_name}} sidecar:

```sh
kubectl get pods -n kong-air-production
```

Every pod reports `2/2` in the `READY` column: one container for the application and one for the sidecar proxy.
