---
title: Split traffic with MeshService resources
content_type: how_to
permalink: /mesh/split-traffic-with-meshservice-resources/
description: Split traffic between two versions of a Kong Air service with versioned MeshService resources and a weighted MeshHTTPRoute.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - on-prem
  - konnect
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 3
faqs:
  - q: "Why does the Service need `appProtocol: http`?"
    a: |
      The control plane copies `appProtocol` from each Kubernetes `Service` port to the `MeshService` that it generates.
      Without `appProtocol`, the port defaults to `tcp`, and `MeshHTTPRoute` doesn't apply to it.
      See [Ports](/mesh/meshservice/#ports).
tldr:
  q: How do I split traffic between different versions of my service?
  a: |
    Give each version its own Kubernetes `Service`, so the control plane generates a `MeshService` for each version. Then:
    1. Target the shared entry point from a `MeshHTTPRoute` `to[].targetRef`.
    2. Assign a `weight` to each `backendRef`, one per versioned `MeshService`.
    3. Verify the split by tallying which pod served each response.
prereqs:
  inline:
    - title: Set up the scenario
      include_content: md/mesh/v3/prereqs/split-traffic-quickstart
cleanup:
  inline:
    - title: Remove the traffic split
      include_content: md/mesh/v3/cleanup/split-traffic
    - title: Remove the Kong Air foundation
      include_content: md/mesh/v3/cleanup/kong-air-foundation
next_steps:
  - text: "How-to: Target workloads and services"
    url: "/mesh/target-workloads-and-services/"
related_resources:
  - text: MeshHTTPRoute
    url: /mesh/policies/meshhttproute/
  - text: Resource scoping
    url: /mesh/resource-scoping/
  - text: Policy targeting and precedence
    url: /mesh/policy-targeting-and-precedence/
---

The Kong Air engineering team is launching Passenger Portal v2.
To keep the rollout safe, the team sends 90% of traffic to the stable `v1` and 10% to the new `v2`.

In this guide, you create one `MeshService` for each version and split traffic between them with a `MeshHTTPRoute`.

For the `MeshService` kinds that `to[].targetRef` accepts, see [Accepted values by field](/mesh/policy-targeting/#accepted-values-by-field).
The next guide, [Target workloads and services](/mesh/target-workloads-and-services/), covers label-based targeting.

<!-- vale off -->
{% table %}
columns:
  - title: Scenario requirement
    key: goal
  - title: Outcome
    key: outcome
rows:
  - goal: Version isolation
    outcome: Kong Air manages `v1` and `v2` as independent resources, each with its own metrics.
  - goal: Weighted distribution
    outcome: The route splits traffic 90/10, whatever the pod count of each version.
  - goal: Resource stability
    outcome: You can add or remove replicas in either version without changing the route.
{% endtable %}
<!-- vale on -->

## Deploy the v2 workload

The Kong Air quickstart deploys only the stable `passenger-portal` workload, labeled `version: v1`.
Deploy a `passenger-portal-v2` workload, labeled `version: v2`, next to it.
The new workload reuses the `nginx-passthrough` ConfigMap that the quickstart created in `kong-air-production`:

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

## Define explicit MeshServices

A canary or blue-green rollout needs one destination for each version, so the route can name each version directly.
Create the `passenger-portal-v1` and `passenger-portal-v2` Kubernetes Services.
The control plane generates a matching `MeshService` from each Service:

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

Confirm that the control plane generated a `MeshService` for each versioned `Service`:

```bash
kubectl get meshservices -n kong-air-production -o name
```

```text
meshservice.kuma.io/check-in-api
meshservice.kuma.io/flight-control
meshservice.kuma.io/passenger-portal
meshservice.kuma.io/passenger-portal-v1
meshservice.kuma.io/passenger-portal-v2
```
{:.no-copy-code}

{:.info}
> On Kubernetes, `kuma.io/display-name` is an annotation, so `kubectl get meshservice --show-labels` doesn't list it.
> When the control plane evaluates a policy, it computes `kuma.io/display-name` from the object name.
> For this reason, `kuma.io/display-name: passenger-portal-v1` selects the `passenger-portal-v1` `MeshService`.

## Configure the weighted route

Create a `MeshHTTPRoute` that splits traffic between `passenger-portal-v1` and `passenger-portal-v2`.
The route lives in `kong-air-production` and selects `passenger-portal` by `kuma.io/display-name` alone, so it's a consumer policy.
A consumer policy with a `Mesh` top-level `targetRef` applies to every client in its own namespace, which includes `check-in-api`.
For details, see [Policy scope](/mesh/policy-targeting/#policy-scope):

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
    kind: Mesh # Applies to every client in kong-air-production
  to:
    - targetRef:
        kind: MeshService
        labels:
          kuma.io/display-name: passenger-portal # The shared booking API entry point
      rules:
        - matches:
            - path: { value: "/", type: PathPrefix }
          default:
            backendRefs:
              - kind: MeshService
                labels:
                  kuma.io/display-name: passenger-portal-v1
                port: 8080
                weight: 90 # 90% traffic to stable
              - kind: MeshService
                labels:
                  kuma.io/display-name: passenger-portal-v2
                port: 8080
                weight: 10 # 10% traffic to canary' | kubectl apply -f -
```

## Authorize check-in-api to call passenger-portal

In [Create a security policy](/mesh/create-a-security-policy/), you gave every Kong Air workload an identity with `MeshIdentity`.
Because of that identity, every workload, including `passenger-portal`, requires mTLS and denies callers that no permission allows.
The mesh-wide `MeshTLS` from that guide only makes the `Strict` mode explicit.
That guide only allowed `flight-control` to call `check-in-api`.

Create a `MeshTrafficPermission` that allows `check-in-api` to call `passenger-portal`:

```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-check-in-to-passenger-portal
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: passenger-portal
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/check-in-api' | kubectl apply -f -
```

## Validate

The Kong Air demo applications don't return a version string.
The nginx-based application returns its pod hostname at `/`.
To find which version served each request, you match each hostname to the pods of each version.

1. Look up the pod names for each version by their `version` label:

   ```sh
   V1_PODS=$(kubectl get pods -n kong-air-production -l app=passenger-portal,version=v1 -o jsonpath='{.items[*].metadata.name}')
   V2_PODS=$(kubectl get pods -n kong-air-production -l app=passenger-portal,version=v2 -o jsonpath='{.items[*].metadata.name}')
   echo "v1 pods: $V1_PODS"
   echo "v2 pods: $V2_PODS"
   ```

1. Send 50 requests from `check-in-api` to the shared `passenger-portal` route.
   The script counts how many responses come from `v1` pods and how many from `v2` pods:

   ```sh
   v1=0; v2=0
   for i in $(seq 1 50); do
     host=$(kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://passenger-portal.kong-air-production.svc.cluster.local:8080/)
     case " $V1_PODS " in *" $host "*) v1=$((v1+1)) ;; esac
     case " $V2_PODS " in *" $host "*) v2=$((v2+1)) ;; esac
   done
   echo "v1=$v1 v2=$v2"
   ```

1. Confirm that the counts are close to the configured 90/10 weights:

   ```text
   v1=45 v2=5
   ```
   {:.no-copy-code}
