---
title: Setup Multi Zone services in {{site.mesh_product_name}}
description: "Learn how to setup Multi Zone services to deal with zone to zone communication, failover and disaster recovery."
content_type: how_to
permalink: /mesh/disaster-recovery/
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
  q: How do I setup Failover and Disaster recovery with {{site.mesh_product_name}}
  a: Use Mesh Multi Zone Services with {{site.base_gateway}} to automatically route traffic to healthy zones.

prereqs:
  inline:
    - title: Create a {{site.mesh_product_name}} control planes
      content: |
        This tutorial requires a {{site.konnect_short_name}} Plus account. If you don't have one, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

        After creating your {{site.konnect_short_name}} account, [create the {{site.mesh_product_name}} control plane](https://cloud.konghq.com/us/mesh-manager/create-control-plane) and your first Mesh zone. Follow the instructions in {{site.konnect_short_name}} to deploy Mesh on your Kubernetes cluster.
    - title: Setup multiple Mesh zones
      content: |
        Use {{site.konnect_short_name}} to create a new zone in [Mesh manager](https://cloud.konghq.com/us/mesh-manager/).  This will be used as the secondary zone to host your workloads and can be in a different data center or Cloud region.
cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---


## Mesh Failover and DR

One of the most difficult things to setup in a Service Mesh is multi zone failover, and communication.  {{site.mesh_product_name}} is built from the ground up to support multiple zones, and seamlessly setup zone to zone communication through MeshMultiZoneServices.

In this walkthrough, we will show you how to create a service that spans multiple zones, as well as how to have an active/active failover for your {{site.kic_product_name}}.

## Target architecture

To demonstrate how to setup a Multi Zone services, we will create two Kubernetes clusters, each being a separate Mesh Zone.  Each Zone will have a {{site.kic_product_name}} that will handle traffic into the zones.  In front of the KIC instances will be a Global Load balancer, which will deal with traffic at the edge.  

### Do I need KIC in both zones?

You actually don't need to have a KIC instance on both zones.  For a partial, or workload only failure, a MeshMultiZoneService will automatically route traffic to:

* The most local instantiation of the Services (this is called Locality aware routing)
* or in the event of a failure, the service hosted in another zone

We've decided to use 2 KIC instances to deal with a scenario where an entire Zone goes down for say, a cloud region failure.
<!--vale off -->
{% mermaid %}
---
config:
  layout: dagre
---
flowchart TB

%% ========== Outer Mesh Box ==========
subgraph MESHBOX["Mesh"]

  %% Zone 1
  subgraph Z1["Cluster: zone1"]
    direction TB
    Z1KIC["Kong Gateway (KO)"]
    Z1ECHO["echo service"]
  end

  %% Zone 2
  subgraph Z2["Cluster: zone2"]
    direction TB
    Z2KIC["Kong Gateway (KO)"]
    Z2ECHO["echo service"]
  end

  %% Kong Mesh Service
  subgraph MESH["MeshMultiZoneService"]
    MMS["echo.mzsvc.mesh.local"]
  end

end

%% External Traffic Flow
EXT["External Clients"] --> GLB["Global Load Balancer"]
GLB --> Z1KIC
GLB --> Z2KIC

Z1KIC -.->|HTTP to echo.mzsvc.mesh.local| MMS
Z2KIC -.->|HTTP to echo.mzsvc.mesh.local| MMS

MMS -.->|zone-local preferred| Z1ECHO
MMS -.->|zone-local preferred| Z2ECHO
{% endmermaid %}
<!--vale on -->

## Setup your zones

This walkthrough is based on using Kubernetes as the compute platform.  The configuration of workloads running on Universal will be exactly the same from a {{site.mesh_product_name}} point of view, and we will use kumactl YAML notation in all of our examples.

### Label your namespaces and deploy your workloads

We will use `kubectx` and `kubens` to navigate between clusters and namespaces. These tools will save you a lot of time!

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

For each Zone, follow the instructions to deploy [Kong Operator](operator/dataplanes/get-started/kic/create-gateway/) into each zone.  

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

{{site.mesh_product_name}} will automatically resolve the Kubernetes ```echo``` service to the Cluster IP address and route traffic through the Mesh dataplanes.  We do not have to to anything.

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

Create the new MMZS by combining the services in both zones based on the ```meshService``` ```matchLabel```.  In this case, we are using the name of the service, but this can be based on workload labels too.

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


## Configure {{site.base_gateway}}

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

## Simulating failover and disaster
This architecture solves for a couple of different scenarios.  To simulate a failover.  Simply deleting the `echo` deployment, service or misconfiguring the service (for example a wrong destination port) would mean that the Mesh would automatically reroute traffic to Zone 2.

In the case of a Zone disaster, deleting the Zone 1 cluster, the Gateway, or the `echo` deployment would also mean traffic is moved to Zone 1.  

If the failover or disaster is temporary, as services, mis-configuration, or regions come back online, the Mesh will automatically reroute traffic to the "happy path" as locality aware routing would make sure calls to the echo service are within the relevant zones.

## What scenarios does Mesh Multi Zone Service help with?
Multi Zones Services are a very powerful construct in {{site.mesh_product_name}}.  As we have both a Global and a Zone control plane, we are able to greatly simplify the configuration of not just routing between Zones, but also creating logical services that can span multiple Zones.

In this example we looked at Failover and DR scenarios that encapsulate traffic entering your environments, but this could equally help with service availability during workload rollouts and upgrades.  Coupled with readiness, health probes, as well as automated functional and non-functional testing, you will be able to maintain a service level objective across multiple environments with zero configuration needed.

