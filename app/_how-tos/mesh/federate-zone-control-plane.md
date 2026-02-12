---
title: 'Federate a zone control plane'
description: 'Learn how to federate a {{site.base_product}} zone control plane into a multi-zone deployment. This guide walks through setting up a global control plane, copying resources, connecting zones, and verifying policy synchronization.'
    
content_type: how_to
permalink: /mesh/federate/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: Set up a built-in gateway with {{site.mesh_product_name}}
    url: '/how-to/set-up-a-built-in-mesh-gateway/'
  - text: 'Producer and Consumer policies'
    url: /mesh/consumer-producer-policies/
  - text: 'Multi-zone deployment'
    url: '/mesh/mesh-multizone-service-deployment/'

min_version:
  mesh: '2.6'

products:
  - mesh

tldr:
  q: How can I federate a zone control plane in a multi-zone deployment?
  a: |
    1. Create a zone control plane and a global control plane in separate Kubernetes clusters.
    1. Copy resources from the zone control plane to the global control plane.
    1. Connect the two control planes by updating the zone control plane's Helm deployment.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}} with demo configuration
      include_content: prereqs/kubernetes/mesh-quickstart

cleanup:
  inline:
    - title: Clean up kumactl control plane
      include_content: cleanup/products/kumactl
    - title: Clean up {{site.mesh_product_name}} resources
      content: |
        To clean up your environment, remove the Docker containers, network, temporary directory, and the control plane configuration. Run the following command:

        ```sh
        minikube delete --profile mesh-zone
        minikube delete --profile mesh-global
        ```
    
---

## Start a new Kubernetes cluster for the global control plane

We've created a zone control plane in the [prerequisites](#install-kong-mesh-with-demo-configuration), now we need a global control plane. The zone a global control planes can't be in the same Kubernetes cluster, so we must start by creating a new cluster:
```sh
minikube start -p mesh-global
```

Use the minikube tunnel feature to provision local load balancer addresses:
```sh
nohup minikube tunnel -p mesh-global &
```

## Deploy the global control plane

Run the following command to deploy a global control plane:

```sh
helm install --kube-context mesh-global --create-namespace --namespace kong-mesh-system \
--set kuma.controlPlane.mode=global \
--set kuma.controlPlane.defaults.skipMeshCreation=true \
kong-mesh kong-mesh/kong-mesh
```

We'll skip the default mesh creation since we'll bring the mesh from the zone control plane in the next steps.

## Set up kumactl

Before we start migrating, we need to set up kumactl, which we'll use to export resources.

1. Run the following command to expose the control plane's API server. We'll need this to access kumactl:

   ```sh
   kubectl --context mesh-zone port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
   ```

1. In a new terminal, check that kumactl is installed and that its directory is in your path:

   ```sh
   kumactl
   ```

   If the command is not found:

   1. Make sure that kumactl is [installed](#install-kumactl)
   1. Add the {{site.mesh_product_name}} binaries directory to your path:

      ```sh
      export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin
      ```

1. Export your admin token and add your control plane:

   ```sh
   export ZONE_USER_ADMIN_TOKEN=$(kubectl --context mesh-zone get secrets -n kong-mesh-system admin-user-token -o json | jq -r .data.value | base64 -d)
   kumactl config control-planes add \
     --address http://localhost:5681 \
     --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
     --name "my-cp" \
     --overwrite
   ```

## Copy resources from the zone control plane to the global control plane

1. Export the external IP to use to access the global control plane:
   ```sh
   export EXTERNAL_IP=host.minikube.internal
   ```

   {:.info}
   > If you're not using minikube, you can find your external IP with this command:
   > ```sh
   > export EXTERNAL_IP=$(kubectl --context mesh-global get svc -n kong-mesh-system kong-mesh-global-zone-sync -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   > ```

1. Export the zone control plane resources:

   ```sh  
   kumactl export --profile federation-with-policies --format kubernetes > resources.yaml
   ```

1. Apply the resources to the global control plane:

   ```sh
   kubectl apply --context mesh-global -f resources.yaml
   ```

## Connect the control planes

Update the zone control plane's Helm deployment to configure the connection to the global control plane:

```sh
helm upgrade --kube-context mesh-zone --namespace kong-mesh-system \
--set kuma.controlPlane.mode=zone \
--set kuma.controlPlane.zone=zone-1 \
--set kuma.ingress.enabled=true \
--set kuma.controlPlane.kdsGlobalAddress=grpcs://$EXTERNAL_IP:5685 \
--set kuma.controlPlane.tls.kdsZoneClient.skipVerify=true \
kong-mesh kong-mesh/kong-mesh
```

## Validate

1. To validate the federation, start by port-forwarding the API service from the global control plane to port 15681 to avoid collision with previous port-forward:

   ```sh
   kubectl --context mesh-global port-forward svc/kong-mesh-control-plane -n kong-mesh-system 15681:5681
   ```

1. In a browser, go to [http://127.0.0.1:15681/gui/](http://127.0.0.1:15681/gui/) to see the GUI.
   
   You should see:

   * A zone in list of zones
   * Policies, including the `MeshTrafficPermission` that we applied in the [prerequisites](#install-kong-mesh-with-demo-configuration)
   * Data plane proxies for the demo application that we installed in the [prerequisites](#install-kong-mesh-with-demo-configuration)

   It can take some time for these to appear, if you don't see them immediately, wait a few minutes and try again.

1. Create the `kong-mesh-demo` namespace in the global control plane:

   ```sh
   kubectl --context mesh-global create namespace kong-mesh-demo
   ```

1. Apply a policy on the global control plane:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshCircuitBreaker
   metadata:
     name: demo-app-to-redis
     namespace: kong-mesh-demo
     labels:
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: demo-app
     to:
     - targetRef:
         kind: MeshService
         name: kv
       default:
         connectionLimits:
           maxConnections: 2
           maxPendingRequests: 8
           maxRetries: 2
           maxRequests: 2" | kubectl --context mesh-global apply -f -
   ```

1. Check that the policy is applied on the zone control plane:
   ```sh
   kubectl get --context mesh-zone meshcircuitbreakers -A
   ```

   You should get the following result:
   ```sh
   NAMESPACE          NAME                                                TARGETREF KIND   TARGETREF NAME
   kong-mesh-system   demo-app-to-redis-65xb45x2xfd5bf7f                  Dataplane        
   kong-mesh-system   mesh-circuit-breaker-all-default                    Mesh             
   kong-mesh-system   mesh-circuit-breaker-all-default-d6zfxc24v7449xfv   Mesh             
   ```
   {:.no-copy-code}