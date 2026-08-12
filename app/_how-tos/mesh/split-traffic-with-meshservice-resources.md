---
title: Split traffic with MeshService resources
content_type: how_to
permalink: /mesh/scenarios/split-traffic-with-meshservice-resources/
description: Implement precise traffic splitting between different service versions using the modern MeshService resource model.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I split traffic between different versions of my service?
  a: |
    Use Explicit Subsetting by:
    1. Defining distinct versioned destinations for each version you want to route independently (for example, `v1` and `v2`).
    2. Using MeshHTTPRoute to assign `weights` to each `backendRef`.
    3. Verifying the split by monitoring the distribution of requests across the named services.
prereqs:
  inline:
    - title: Architecture
      content: |
        A {{site.mesh_product_name}} deployment with `meshServices.mode: Exclusive` enabled.
    - title: Workloads
      content: |
        Multiple versions of a service (for example, `passenger-portal`) deployed with identifying labels.
next_steps:
  - text: "Target workloads and services"
    url: "/mesh/scenarios/target-workloads-and-services/"
related_resources:
  - text: MeshHTTPRoute
    url: /mesh/policies/meshhttproute/
  - text: MeshService
    url: /mesh/meshservice/
  - text: Policy targeting and precedence
    url: /mesh/scenarios/policy-targeting-and-precedence/
---

The Kong Air engineering team is launching a new Passenger Portal v2. To ensure a smooth transition, they want to route 90% of traffic to the stable `v1` and 10% to the new `v2` for a group of internal pilot users. 

This guide demonstrates how to achieve this using explicit `MeshService` versions routed by a `MeshHTTPRoute`. If you want a refresher on the `targetRef` model and where `MeshService` fits in `to[]`/`backendRefs`, see [Policy targeting and precedence](/mesh/scenarios/policy-targeting-and-precedence/); the [Target workloads and services](/mesh/scenarios/target-workloads-and-services/) guide that follows goes deeper on label-based targeting.

## What this proves

<!-- vale off -->
{% table %}
columns:
  - title: Scenario Requirement
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Version Isolation
    outcome: Kong Air can manage `v1` and `v2` as independent, first-class resources with their own metrics.
  - goal: Weighted Distribution
    outcome: Traffic is precisely divided (90/10) without relying on fragile pod counts.
  - goal: Resource Stability
    outcome: Adding or removing pods in either version does not require updating the routing policy.
{% endtable %}
<!-- vale on -->

### The traffic split

{% mermaid %}
graph TD
    User([User Request]) --> Gateway["{{site.base_gateway}}"]
    Gateway --> Route{"MeshHTTPRoute"}
    Route -->|"90% Weight"| Stable["passenger-portal-v1 (MeshService)"]
    Route -->|"10% Weight"| Canary["passenger-portal-v2 (MeshService)"]
{% endmermaid %}

## Configuration

### Deploy the v2 workload

The Kong Air quickstart only deploys the stable `passenger-portal` `version: v1` workload. Deploy a `version: v2` workload alongside it, reusing the same `nginx-passthrough` ConfigMap the quickstart already created in `kong-air-production`:

```bash
echo 'apiVersion: apps/v1
kind: Deployment
metadata:
  name: passenger-portal-v2
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: passenger-portal
      version: v2
  template:
    metadata:
      labels:
        app: passenger-portal
        version: v2
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
            name: nginx-passthrough' | kubectl apply -f -
kubectl wait -n kong-air-production --for=condition=available --timeout=120s deployment/passenger-portal-v2
```

### Define explicit MeshServices

For rollout patterns like canary and blue/green, you want version-specific destinations that the route can name directly. For how {{site.mesh_product_name}} generates `MeshService` resources, how label-based matching works, and what `meshServices.mode: Exclusive` changes, see [MeshService](/mesh/meshservice/).

Create versioned Services (`passenger-portal-v1`, `passenger-portal-v2`) and let {{site.mesh_product_name}} generate the matching `MeshService` resources from them.

{:.info}
> Why `appProtocol: http`? The Kubernetes `Service` example below sets `appProtocol: http` on the port. In `Exclusive` mode, {{site.mesh_product_name}} reads this field to set the protocol on the generated `MeshService`. Without it, the `MeshService` defaults to `tcp`, and HTTP-aware policies, `MeshHTTPRoute`, weighted splits, retries on `5xx`, silently won't apply. Always set `appProtocol` on Services you intend to route at L7.

```bash
echo 'apiVersion: v1
kind: Service
metadata:
  name: passenger-portal-v1
  namespace: kong-air-production
spec:
  selector:
    app: passenger-portal
    version: v1
  ports:
    - port: 8080
      targetPort: 8080
      appProtocol: http
---
apiVersion: v1
kind: Service
metadata:
  name: passenger-portal-v2
  namespace: kong-air-production
spec:
  selector:
    app: passenger-portal
    version: v2
  ports:
    - port: 8080
      targetPort: 8080
      appProtocol: http' | kubectl apply -f -
```

### Configure the weighted route

Now, create a `MeshHTTPRoute` that distributes traffic between these two resources. The top-level `targetRef` is `Mesh`, so the split applies to every client that calls `passenger-portal`. For how `backendRefs` and `weight` divide traffic across the two versions, see [MeshHTTPRoute](/mesh/policies/meshhttproute/). (To roll the split out to only some clients first, narrow the top level to `Dataplane` with a `labels:` selector.)

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: booking-traffic-split
  namespace: kong-air-production
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Mesh # Applies to every client that calls passenger-portal
  to:
    - targetRef:
        kind: MeshService
        name: passenger-portal # The shared booking API entry point
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                name: passenger-portal-v1
                port: 8080
                weight: 90 # 90% traffic to stable
              - kind: MeshService
                name: passenger-portal-v2
                port: 8080
                weight: 10 # 10% traffic to canary' | kubectl apply -f -
```

{:.info}
> Because we used explicit `MeshService` resources, you can go to your Prometheus dashboard and see metrics broken down by `passenger-portal-v1` and `passenger-portal-v2` as separate entities, without needing to adjust your PromQL queries for complex tag filtering.

## Validate

The Kong Air demo apps don't echo a version string, the nginx-based app just returns its pod hostname at `/`. Resolve which pod names belong to each version, then use those hostnames to tell which version served each request.

1. Look up the pod names for each version by label, since the response body is just a hostname, not a version label:

   ```sh
   V1_PODS=$(kubectl get pods -n kong-air-production -l app=passenger-portal,version=v1 -o jsonpath='{.items[*].metadata.name}')
   V2_PODS=$(kubectl get pods -n kong-air-production -l app=passenger-portal,version=v2 -o jsonpath='{.items[*].metadata.name}')
   echo "v1 pods: $V1_PODS"
   echo "v2 pods: $V2_PODS"
   ```

1. Send a batch of requests through the shared `passenger-portal` route from an in-mesh client (here, `check-in-api`), and tally each response's hostname against the pod lists from the previous step:

   ```sh
   v1=0; v2=0
   for i in $(seq 1 50); do
     host=$(kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://passenger-portal.kong-air-production.svc.cluster.local:8080/)
     case " $V1_PODS " in *" $host "*) v1=$((v1+1)) ;; esac
     case " $V2_PODS " in *" $host "*) v2=$((v2+1)) ;; esac
   done
   echo "v1=$v1 v2=$v2"
   ```

1. Confirm the observed distribution is close to the configured 90/10 weight:

   Expected output (allow for some variance across 50 requests):

   ```text
   v1=45 v2=5
   ```
   {:.no-copy-code}
