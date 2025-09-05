---
title: Targeting MeshHTTPRoutes in supported policies
content_type: reference
description: 'Target `MeshHTTPRoutes` in policies like `MeshTimeout`, `MeshAccessLog`, and `MeshRetry` for precise traffic control.'
layout: reference
products:
  - mesh
works_on:
  - konnect
  - on-prem
breadcrumbs:
  - /mesh/
---

Use `MeshHTTPRoute` as a target in supported policies like `MeshTimeout`, `MeshAccessLog`, and `MeshRetry` to apply fine-grained traffic control to specific HTTP methods and paths instead of entire services.

## Prerequisites

Complete the [Kubernetes quickstart](/mesh/kubernetes/) and deploy the demo application with mTLS enabled:

```bash
helm upgrade --install --create-namespace --namespace kuma-system kuma kuma/kuma

kubectl wait -n kuma-system --for=condition=ready pod --selector=app=kuma-control-plane --timeout=90s

kubectl apply -f https://bit.ly/kuma-demo-mtls

kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s

kubectl port-forward svc/demo-app -n kuma-demo 5050:5050 &
```

Verify the demo app is running:

```bash
curl -XPOST localhost:5050/api/counter
```

Expected output:

```json
{"counter":1,"zone":""}
```

## Apply a `MeshTimeout` policy

Limit request duration from `demo-app` to `kv` to 1 second:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: demo-app-to-kv-meshservice
  namespace: kuma-demo
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
        http:
          requestTimeout: 1s
EOF
```

Then simulate a delay with a `MeshHTTPRoute`:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: demo-app-kv-api
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
    - targetRef:
        kind: MeshService
        name: kv
      rules:
        - matches:
            - path:
                type: Exact
                value: "/api/key-value/counter"
              method: POST
          default:
            filters:
              - type: RequestHeaderModifier
                requestHeaderModifier:
                  set:
                    - name: x-set-response-delay-ms
                      value: "2000"
EOF
```

Call the endpoint again:

```bash
curl -XPOST localhost:5050/api/counter
```

You should receive a timeout response:

```json
{"instance":"...","status":504,"title":"failed sending request","type":"..."}
```

## Update timeout for MeshHTTPRoute

Apply a new timeout for the route:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTimeout
metadata:
  name: demo-app-kv-api-meshhttproute
  namespace: kuma-demo
spec:
  to:
    - targetRef:
        kind: MeshHTTPRoute
        name: demo-app-kv-api
      default:
        http:
          requestTimeout: 3s
EOF
```

Re-run the request:

```bash
curl -XPOST localhost:5050/api/counter
```

This time the request should succeed after a delay:

```json
{"counter":3,"zone":""}
```

## Clean up

Remove timeouts and delay:

```bash
kubectl delete meshtimeout demo-app-to-kv-meshservice -n kuma-demo
kubectl delete meshtimeout demo-app-kv-api-meshhttproute -n kuma-demo
```

Reset the route:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshHTTPRoute
metadata:
  name: demo-app-kv-api
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
    - targetRef:
        kind: MeshService
        name: kv
      rules:
        - default: {}
          matches:
            - path:
                type: Exact
                value: "/api/key-value/counter"
              method: POST
EOF
```

## Log traffic with `MeshAccessLog`

Create an access log policy targeting the route:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshAccessLog
metadata:
  name: demo-app-kv-api
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
    - targetRef:
        kind: MeshHTTPRoute
        name: demo-app-kv-api
      default:
        backends:
          - type: File
            file:
              path: "/dev/stdout"
EOF
```

Trigger the route:

```bash
curl -XPOST localhost:5050/api/counter
```

Check logs:

```bash
kubectl logs -n kuma-demo -l app=demo-app -c kuma-sidecar
```

## Apply a `MeshRetry` policy

Remove the default retry policy:

```bash
kubectl delete meshretry mesh-retry-all-default -n kuma-system
```

Inject faults:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshFaultInjection
metadata:
  name: kv-503
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  from:
    - targetRef:
        kind: Mesh
      default:
        http:
          - abort:
              httpStatus: 503
              percentage: 50
EOF
```

Create a retry policy for the route:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: demo-app-kv-http
  namespace: kuma-demo
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  to:
    - targetRef:
        kind: MeshHTTPRoute
        name: demo-app-kv-api
      default:
        http:
          numRetries: 10
          retryOn:
            - "503"
EOF
```

Add a broader retry for all traffic to `kv`:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: demo-app-kv
  namespace: kuma-demo
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
        http:
          numRetries: 10
          retryOn:
            - 5xx
EOF
```

## What you've learned

* Apply `MeshTimeout` policies targeting `MeshHTTPRoute`
* Use `MeshAccessLog` to log only matching traffic
* Create `MeshRetry` policies scoped to `MeshHTTPRoute` and `MeshService`
* Combine policies for precise traffic control

## Next steps

* Learn more about [MeshHTTPRoute](/mesh/policies/meshhttproute/)
* Combine policies like `MeshFaultInjection`, `MeshRetry`, and `MeshTimeout`
* Explore `MeshCircuitBreaker` and `MeshRateLimit` with `MeshHTTPRoute` targeting
