---
title: 'Federate zone control plane'
description: 'Learn how to federate a {{site.base_product}} zone control plane into a multi-zone deployment. This guide walks through setting up a global control plane, copying resources, connecting zones, and verifying policy synchronization.'
    
content_type: how_to
permalink: /mesh/federate/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: Add a builtin gateway
    url: '/mesh/add-builtin-gateway/'
  - text: 'Producer and Consumer policies'
    url: /mesh/consumer-producer-policies/
  - text: 'Multi-zone deployment'
    url: '/mesh/mesh-multizone-service-deployment/'

min_version:
  mesh: '2.6'

products:
  - mesh

tldr:
  q: ""
  a: ""

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



```sh
kubectl --context mesh-zone port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
```

New terminal:

Export the 
```sh
export EXTERNAL_IP=host.minikube.internal
```

```sh
export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin
```

```sh
export ZONE_USER_ADMIN_TOKEN=$(kubectl --context mesh-zone get secrets -n kong-mesh-system admin-user-token -o json | jq -r .data.value | base64 -d)
kumactl config control-planes add \
  --address http://localhost:5681 \
  --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
  --name "my-cp" \
  --overwrite  
  
kumactl export --profile federation-with-policies --format kubernetes > resources.yaml
```

```sh
kubectl apply --context mesh-global -f resources.yaml
```

```sh
helm upgrade --kube-context mesh-zone --namespace kong-mesh-system \
--set kuma.controlPlane.mode=zone \
--set kuma.controlPlane.zone=zone-1 \
--set kuma.ingress.enabled=true \
--set kuma.controlPlane.kdsGlobalAddress=grpcs://$EXTERNAL_IP:5685 \
--set kuma.controlPlane.tls.kdsZoneClient.skipVerify=true \
kong-mesh kong-mesh/kong-mesh
```

```sh
kubectl --context mesh-global port-forward svc/kong-mesh-control-plane -n kong-mesh-system 15681:5681
```

Wait a few minutes

[http://127.0.0.1:15681/gui/]()

```sh
kubectl --context mesh-global create namespace kong-mesh-demo
```

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

```sh
kubectl get --context mesh-zone meshcircuitbreakers -A
```

```sh
NAMESPACE          NAME                                                TARGETREF KIND   TARGETREF NAME
kong-mesh-system   demo-app-to-redis-65xb45x2xfd5bf7f                  Dataplane        
kong-mesh-system   mesh-circuit-breaker-all-default                    Mesh             
kong-mesh-system   mesh-circuit-breaker-all-default-d6zfxc24v7449xfv   Mesh             
```
{:.no-copy-code}