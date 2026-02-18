---
title: Migrate {{site.mesh_product_name}} Services to mTLS
description: Progressively roll in mutual TLS with the MeshTLS policy in {{site.mesh_product_name}} without disrupting traffic.
    
content_type: how_to
permalink: /how-to/migrate-services-to-mtls/

bread-crumbs: 
  - /mesh/

related_resources:
  - text: MeshTLS policy
    url: /mesh/policies/meshtls/
  - text: Resource sizing guidelines
    url: /mesh/resource-sizing-guidelines/
  - text: Version compatibility
    url: /mesh/version-compatibility/

min_version:
  mesh: '2.9'

products:
  - mesh

tldr:
  q: TODO
  a: |
    TODO

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart
    - title: Deploy a second demo Service
      include_content: prereqs/mesh-migration-service
   
---

## Allow traffic on the mesh

Run the following command to add a `MeshTrafficPermission` policy that allows all traffic from inside the mesh:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kong-mesh-system
  name: mtp
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow" | kubectl apply -f -
```

## Port-forward the two Services

In order to interact with the two `demo-app` Services we created in the prerequisites, we need to enable port-forwarding.

1. Run the following command to port-forward the [first Service](#install-kong-mesh-with-demo-configuration):
   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5051:5050
   ```

1. Go to <http://localhost:5051/> to access the demo app's UI and select the **Auto Increment** checkbox to automatically send requests to the Service.

1. In a new terminal window, run the following command to port-forward the [second Service](#deploy-a-second-demo-service):
   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo-migration 5052:5050
   ```

1. Go to <http://localhost:5052/> and select the **Auto Increment** checkbox.


## Enable MeshTLS in permissive mode

In a new terminal window, run the following command to enable the [`MeshTLS`](/mesh/policies/meshtls/) policy in permissive mode for the `kv` app in the `kong-mesh-demo-migration` namespace:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kv
  namespace: kong-mesh-demo-migration
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  rules:
  - default:
      mode: Permissive" | kubectl apply -f -
```

## Add the second Service to the mesh

1. Run the following command to enable sidecar injection on the `kong-mesh-demo-migration` namespace to add its Pods to the mesh:

   ```sh
   kubectl label namespace kong-mesh-demo-migration kuma.io/sidecar-injection=enabled --overwrite
   ```

1. Restart the `kv` Pod to apply the changes:

   ```sh
   kubectl rollout restart deployment kv -n kong-mesh-demo-migration
   ```

   {:.info}
   > This can take a few minutes, make sure to wait until it's completed to move on to the next step.

## Check that the Service is receiving traffic

1. Once the `kv` Pod has restarted, enable port-forwarding for the control plane:

   ```sh
   kubectl port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
   ```

1. In a new terminal window, export the name of the `kv` data plane proxies :
   ```sh
   export KV_DPP_NAME_1=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=kv | jq -c '.items[] | select( .labels["k8s.kuma.io/namespace"]=="kong-mesh-demo")' | jq -r '.name')
   export KV_DPP_NAME_2=$(curl -s http://localhost:5681/meshes/default/dataplanes/_overview\?name\=kv | jq -c '.items[] | select( .labels["k8s.kuma.io/namespace"]=="kong-mesh-demo-migration")' | jq -r '.name')
   ```

1. Run the following command to get the request metrics for the data plane proxies:

   ```sh
   for i in {1..2}; do
    sleep 30
    print 'Service kong-mesh-demo'
    curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME_1/stats | grep cluster.localhost_5050.upstream_rq_2xx
    curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME_1/stats | grep http.localhost_5050.rbac.allowed
    print 'Service kong-mesh-demo-migration'
    curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME_2/stats | grep cluster.localhost_5050.upstream_rq_2xx
    curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME_2/stats | grep http.localhost_5050.rbac.allowed
   done
   ```

   You should get a response similar to this:

   ```
   Service kong-mesh-demo
   cluster.localhost_5050.upstream_rq_2xx: 871
   http.localhost_5050.rbac.allowed: 1310
   Service kong-mesh-demo-migration
   cluster.localhost_5050.upstream_rq_2xx: 5
   http.localhost_5050.rbac.allowed: 0
   Service kong-mesh-demo
   cluster.localhost_5050.upstream_rq_2xx: 873
   http.localhost_5050.rbac.allowed: 1313
   Service kong-mesh-demo-migration
   cluster.localhost_5050.upstream_rq_2xx: 7
   http.localhost_5050.rbac.allowed: 0
   ```

   Between the two iterations, you should see:
   * The `cluster.localhost_5050.upstream_rq_2xx` and `http.localhost_5050.rbac.allowed` values increase for the data plane proxy in the `kong-mesh-demo` namespace.
   * The `cluster.localhost_5050.upstream_rq_2xx` value increase and the `http.localhost_5050.rbac.allowed` value remain at 0 for the data plane proxy in the `kong-mesh-demo-migration` namespace.

   This indicates that the proxy in `kong-mesh-demo-migration` namespace is not receiving encrypted traffic, because the `demo-app` data plane proxy is not in the mesh.



## Migrate the demo app client to the mesh

1. Run the following command restart the `demo-app` Pod from the `kong-mesh-demo-migration` namespace and add it to the mesh:

   ```sh
   kubectl rollout restart deployment demo-app -n kong-mesh-demo-migration
   ```

   {:.info}
   > * This can take a few minutes, make sure to wait until it's completed to move on to the next step.
   > * Once the restart is done, port-forwarding will stop for this Service.


1. Run the following command re-enable port-forwarding:
   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo-migration 5052:5050
   ```

1. Go to <http://localhost:5052/> and select the **Auto Increment** checkbox to send requests to the Service.

1. In a new terminal window, run the following command to get the encrypted request metrics for the data plane proxy in the `kong-mesh-demo-migration` namespace:

   ```sh
   for i in {1..2}; do
    sleep 30
    curl -s http://localhost:5681/meshes/default/dataplanes/$KV_DPP_NAME_2/stats | grep http.localhost_5050.rbac.allowed
   done
   ```

   This value should now be increasing:

   ```
   http.localhost_5050.rbac.allowed: 5351
   http.localhost_5050.rbac.allowed: 6254
   ```

## Update the MeshTLS policy

To disable unencrypted traffic, update the `MeshTLS` policy from permissive to strict:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTLS
metadata:
  name: kv
  namespace: kong-mesh-demo-migration
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  rules:
  - default:
      mode: Strict" | kubectl apply -f -
```

The Service can now only receive encrypted traffic.