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
--set controlPlane.mode=global \
--set controlPlane.defaults.skipMeshCreation=true \
kong-mesh kong-mesh/kong-mesh
```

We'll skip the default mesh creation since we'll bring the mesh from the zone control plane in the next steps.

Export the 
```sh
export EXTERNAL_IP=host.minikube.internal
```

```sh
kubectl --context mesh-zone port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
```

```sh
export ZONE_USER_ADMIN_TOKEN=$(kubectl --context mesh-zone get secrets -n kong-mesh-system admin-user-token -o json | jq -r .data.value | base64 -d)
kumactl config control-planes add \
  --address http://localhost:5681 \
  --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
  --name "zone-cp" \
  --overwrite  
  
kumactl export --profile federation-with-policies --format kubernetes > resources.yaml
```