---
title: "{{site.mesh_product_name}} disaster recovery"
description: "Learn how to set up multi zone services to deal with zone-to-zone communication, failover, and disaster recovery."
content_type: reference
layout: reference
breadcrumbs: 
  - /mesh/
products:
  - mesh
tags: 
  - zones
  - failover
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Observability"
    url: /mesh/observability/
  - text: "{{site.mesh_product_name}} features"
    url: /mesh/
---

## Mesh failover and disaster recovery

One of the most difficult things to set up in a service Mesh is multi zone failover and communication. {{site.mesh_product_name}} is built from the ground up to support multiple zones and seamlessly set up zone-to-zone communication through `MeshMultiZoneServices`.

In this walkthrough, we will show you how to create a service that spans multiple zones, as well as how to have an active/active failover for your {{site.kic_product_name}}.

## Target architecture

To demonstrate how to set up multi zone services, we will create two Kubernetes clusters, each being a separate Mesh Zone. Each zone will have a {{site.kic_product_name}} that will handle traffic into the zones.  
In front of the KIC instances will be a global Load Balancer, which will deal with traffic at the edge.

### Do I need KIC in both zones?

You actually don't need to have a KIC instance in both zones. For a partial or workload-only failure, a MeshMultiZoneService will automatically route traffic to:

* The most local instantiation of the services (this is called locality-aware routing)
* Or, in the event of a failure, the service hosted in another zone

We've decided to use two KIC instances to deal with a scenario where an entire zone goes down — for example, a cloud region failure.

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

## Configure your zones

This walkthrough is based on using Kubernetes as the compute platform. The configuration of workloads running on Universal will be exactly the same from a {{site.mesh_product_name}} point of view, and we will use kumactl YAML notation in all of our examples.

### Label your namespaces and deploy workloads

We will use `kubectx` and `kubens` to navigate between clusters and namespaces. These tools will save you a lot of time!

Let's go ahead and create a namespace in each zone, label the namespaces so that workloads that land there are part of the Mesh, and deploy our Echo workload and Kubernetes service:

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

### Deploy {{site.operator_product_name}}

For each zone, follow the instructions to deploy [{{site.operator_product_name}}](/operator/get-started/gateway-api/deploy-gateway/) into each zone.

The Gateway will need to be part of the Mesh, so make sure your Dataplanes are deployed into the `kong` namespace that has been marked as being part of the Mesh.

### Create a test HTTPRoute

Let's test that everything in each zone is correctly plumbed together by deploying an HTTPRoute for our zone-based echo service.

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

{{site.mesh_product_name}} will automatically resolve the Kubernetes `echo` service to the Cluster IP address and route traffic through the Mesh dataplanes. We do not have to do anything.

Test the route has been created and programmed by calling the `echo` service through the Gateway:

```sh
curl http://${GATEWAY_IP}/echo

Welcome, you are connected to node mesh-zone2.
Running on Pod echo-6bf5d86c87-6f6hg.
In namespace kong.
With IP address 10.244.0.36.
```

This confirms that the service is reachable by the Gateway.

## Set up a Mesh Multi Zone service

A MeshMultiZoneService (MMZS) uses the Mesh to bring together services in more than one zone. Traffic between each zone will leave the zone (egress) through the `zone1` Egress gateway and enter (ingress) `zone2` at its Ingress gateway.

Create the new MMZS by combining the services in both zones based on the `meshService` `matchLabel`. In this case, we are using the name of the service, but this can be based on workload labels too.

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

As an MMZS is a global Mesh construct, it is defined at the global control plane. The multi zone service will *not* resolve through cluster DNS and can only be accessed from within the Mesh. The Mesh dataplanes are responsible for routing traffic from one workload to another.  
Kubernetes Gateway API expects to resolve backend services to a Kubernetes service, and as this does not exist for a Multi Zone service, we need to create an ExternalName resource:

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

This is effectively a CNAME from a Kubernetes service to the Mesh Multi Zone service. As the Gateway is part of the Mesh, this will be resolved correctly.

Let's go back and change our original test service in zone 1 to point at our new multi zone service.

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

For our scenario, we can apply the changes to both Gateways so that traffic will be correctly routed from one zone to another based on the echo service's health and availability.

## Simulating failover and disaster

This architecture solves for a couple of different scenarios. To simulate a failover, simply deleting the `echo` deployment, service, or misconfigured the service (for example, a wrong destination port) would mean that the Mesh would automatically reroute traffic to zone 2.

In the case of a zone disaster, deleting the zone 1 cluster, the Gateway, or the `echo` deployment would also mean traffic is moved to zone 2.

If the failover or disaster is temporary, as services, misconfiguration, or regions come back online, the Mesh will automatically reroute traffic to the "happy path," as locality-aware routing ensures calls to the echo service stay within the relevant zones.

## What scenarios does Mesh Multi Zone service help with?

Multi Zone services are a very powerful construct in {{site.mesh_product_name}}. As we have both a global and a zone control plane, we are able to greatly simplify the configuration of not just routing between Zones, but also creating logical services that can span multiple Zones.

In this example, we looked at failover and disaster recovery scenarios that encapsulate traffic entering your environments, but this could equally help with service availability during workload rollouts and upgrades. Coupled with readiness and health probes, as well as automated functional and non-functional testing, you will be able to maintain a service level objective across multiple environments with zero configuration needed.