---
title: Setup Multi Zone services in Kong Mesh
description: "Learn how to setup Multi Zone services to deal with zone to zone communication, failover and disaster recovery."
content_type: how_to
permalink: /mesh/mesh-dr/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/

products:
  - mesh

works_on:
  - konnect
  - on-prem

tldr:
  q: How do I setup Failover and Disaster recovery with Kong Mesh
  a: Use Mesh Multi Zone Services with Kong Gateway to automatically route traffic to healthy zones.

prereqs:
  inline:
    - title: Create a {{site.mesh_product_name}} Control Plane
      content: |
        This tutorial requires a {{site.konnect_short_name}} Plus account. If you don't have one, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

        After creating your {{site.konnect_short_name}} account, [create the Kong Mesh Control Plane](https://cloud.konghq.com/us/mesh-manager/create-control-plane) and your first Mesh zone. Follow the instructions in {{site.konnect_short_name}} to deploy Mesh on your Kubernetes cluster.
    - title: Setup multiple Mesh zones
      content: |
        Use {{site.konnect_short_name}} to create a new zone in [Mesh manager](https://cloud.konghq.com/us/mesh-manager/).  This will be used as the secondary zone to host your workloads and can be in a different datacenter or Cloud region.
cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---


## Mesh Failover and DR

One of the most difficult things to setup in a Service Mesh is multi zone failover, and communication.  Kong Mesh is built from the ground up to support multiple zones, and seamlessly setup zone to zone communication through MeshMultiZoneServices.

In this walkthrough, we will show you how to create a service that spans multiple zones, as well as how to have an active/active failover for your Kong Ingress controllers.

## Our target architecture

To demonstrate how to setup a Multi Zone services, we will create two Kubernetes clusters, each being a separate Mesh Zone.  Each Zone will have a Kong Ingress Controller that will handle traffic into the zones.  In front of the KIC instances will be a Global Load balancer, which will deal with traffic at the edge.  

### Do I need KIC in both zones?

You actually don't need to have a KIC instance on both zones.  For a partial, or workload only failure, a MeshMultiZoneService will automatically route traffic to:

* The most local instantiation of the Services (this is called Locality aware routing)
* ...or in the event of a failure, the service hosted in another zone

We've decided to use 2 KIC instances to deal with a scenario where an entire Zone goes down for say, a Cloud region failure.

{% mermaid %}
---
config:
  layout: dagre
---
flowchart LR
 subgraph MESH["Kong Mesh"]
        MMS[("Multi Zone Service")]
  end
 subgraph Z1Edge["Kong Operator (edge)"]
        Z1KIC1["Kong Gateway"]
  end
 subgraph Z1Apps["Workloads"]
        Z1DEP["Deployment: echo"]
        Z1SVC(["Service: echo"])
  end
 subgraph Z1["Kubernetes Cluster: zone1 (Mesh Zone: zone1)"]
        Z1Edge
        Z1Apps
  end
 subgraph Z2Edge["Kong Operator (edge)"]
        Z2KIC1["Kong Gateway"]
  end
 subgraph Z2Apps["Workloads"]
        Z2DEP["Deployment: echo"]
        Z2SVC(["Service: echo"])
  end
 subgraph Z2["Kubernetes Cluster: zone2 (Mesh Zone: zone2)"]
        Z2Edge
        Z2Apps
  end
    ext["External Clients"] --> GLB[("Global Load Balancer")]
    Z1DEP --> Z1SVC
    Z2DEP --> Z2SVC
    GLB --> Z1KIC1  & Z2KIC1 
    Z1KIC1 -. "HTTP to\n<code>echo.&lt;mesh&gt;.svc</code>" .-> MMS
    Z2KIC1 -. "HTTP to\n<code>echo.&lt;mesh&gt;.svc</code>" .-> MMS
    MMS -. "zone-local preferred" .-> Z1SVC & Z2SVC
    Z1DEP@{ shape: rect}
    Z2DEP@{ shape: rect}
    ext@{ shape: rounded}
{% endmermaid %}

## Setup your zones

This walkthrough is based on using Kubernetes as the compute platform.  The configuration of workloads running on Universal will be exactly the same from a Kong Mesh point of view, and we will use kumactl YAML notation in all of our examples.

### Label your namespaces and deploy your workloads

We will use ```kubectx``` and ```kubens``` to navigate between clusters and namespaces.  These tools will save you a lot of time!

Let's go ahead and create a namespace in each zone, label the namespaces so that workloads that will land there to be part of the Mesh and deploy our Echo workload and Kubernetes service:

```sh
kubectx zone1
kubectl create namespace kong
kubectl label namespace kong kuma.io/sidecar-injection=enabled
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong

kubectx zone2
kubectl create namespace kong
kubectl label namespace kong kuma.io/sidecar-injection=enabled
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

### Deploy Kong Operator

For each Zone, follow the instructions to deploy [Kong Operator](https://developer.konghq.com/operator/dataplanes/get-started/kic/create-gateway/) into each zone.  

The Gateway will need to be part of the Mesh, so make sure your Dataplanes are deployed into the ```kong``` namespace that has been marked as being part of the Mesh.

### Create a test HTTPRoute

Let's test that everything in each Zone is correctly plumbed together by deploying an HTTPRoute for our Zone based echo service.

```sh
echo '
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: echo
  namespace: kong
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo
          port: 1027
' | kubectl apply -f -
```

Kong Mesh will automatically resolve the Kubernetes ```echo``` service to the Cluster IP address and route traffic through the Mesh dataplanes.  We do not have to to anything 

Test the route has been created, and programmed by calling the ```echo``` service through the Gateway:

```sh
curl http://${GATEWAY_IP}/echo

Welcome, you are connected to node mesh-zone2.
Running on Pod echo-6bf5d86c87-6f6hg.
In namespace kong.
With IP address 10.244.0.36.
```

This confirms that the Service is reachable by the Gateway.

## Setup a Mesh Multi Zone Service

A MeshMultiZoneService (MMZS) uses the Mesh to bring together services in more than one zone.  Traffic between each Zone will leave the Zone (egress) through the zone1 Egress gateway, and enter (ingress) Zone 2 at its Ingress gateway.

Create the new MMZS by combining the services in both zones based on the meshService matchLabel.  In this case, we are using the name of the service, but this can be based on workload labels too.

```sh
echo 'type: MeshMultiZoneService
name: echo
mesh: default
spec:
  selector:
    meshService:
      matchLabels:
        kuma.io/display-name: echo
  ports:
  - port: 1027' | kumactl apply -f -
```


## Configure Kong Gateway

As a MMZS is a Global Mesh construct, it is defined at the Global control plane.  The multi zone service will *not* resolve through cluster DNS, and can only be accessed from within the Mesh.  The Mesh dataplanes are responsible for routing traffic from one workload to another.

Kubernetes Gateway API expects to resolve back end services to a Kubernetes service, and as this does not exist for a Multi Zones service, we need to create an External Name resource:

```sh
echo '
apiVersion: v1
kind: Service
metadata:
  name: echo-mmzs-service
  namespace: kong
spec:
  type: ExternalName
  externalName: echo.mzsvc.mesh.local
  ports:
  - name: http
    port: 1027
    targetPort: 1027' | kubectl apply -f -
```

This is effectively a CNAME from a Kubernetes service to the Mesh Multi Zone Service.  As the Gateway is part of the Mesh, this will be resolved correctly.

Let's go back and change our original test service in Zone 1 to point at our new multi-zone service.

```sh
echo '
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: echo
  namespace: kong
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      backendRefs:
        - name: echo-mmzs-service # <-- change the service backendRef
          port: 1027
' | kubectl apply -f -
```

For our scenario, we can apply the changes to both Gateways so that traffic will be correctly routed from one Zone to another based on the echo service's health and availability.

## What scenarios does Mesh Multi Zone Service help with?
Multi Zones Services are a very powerful construct in Kong Mesh.  As we have both a Global and a Zone control plane, we are able to greatly simplify the configuration of not just routing between Zones, but also creating logical services that can span multiple Zones.

In this example we looked at Failover and DR scenarios that encapsulate traffic entering your environments, but this could equally help with service availability during workload rollouts and upgrades.  Coupled with readiness, health probles, as well as automated functional and non-functional testing, you will be able to maintain a service level objective across multiple environments with zero configuration needed.

