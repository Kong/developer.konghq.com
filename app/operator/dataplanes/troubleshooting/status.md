---
title: "Status"
description: "Inspect resource statuses to see detailed information about {{ site.gateway_operator_product_name }} resources"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Troubleshooting

---

Resources managed by {{ site.gateway_operator_product_name }} provide the `status` field like other Kubernetes objects.

To see object's status you can use the `kubectl get` command:

```bash
kubectl get $TYPE $NAME -o jsonpath-as-json='{.status}'
```

The above command will yield a JSON object which depends on the actual schema of the status field and the state of the object.

## ControlPlane

Assuming a `ControlPlane` called `kong`, you can obtain its status using the following `kubectl` command:

```bash
kubectl get controlplane kong -o jsonpath-as-json='{.status}'
```

Which will show an output similar to:

```json
[
    {
        "conditions": [
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "",
                "observedGeneration": 3,
                "reason": "Ready",
                "status": "True",
                "type": "Ready"
            },
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "pods for all Deployments are ready",
                "observedGeneration": 3,
                "reason": "PodsReady",
                "status": "True",
                "type": "Provisioned"
            }
        ]
    }
]
```

## DataPlane

Let's use the following `DataPlane` as an example:

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: example
spec:
  deployment:
    podTemplateSpec:
      metadata:
        labels:
          dataplane-pod-label: example
        annotations:
          dataplane-pod-annotation: example
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }} ' | kubectl apply -f -
```

To wait for the `DataPlane` to get ready, we can use the following command:

```bash
kubectl wait -n default dataplane example --for=condition=Ready
```

After a couple of seconds we should see:

```bash
dataplane.gateway-operator.konghq.com/example condition met
```

Once the `DataPlane` is deployed we can fetch information from its `status` field.

For example, if you'd like to get its addresses you can run:

```bash
kubectl get -n default dataplane example -o jsonpath-as-json='{.status.addresses}'
```

Which could yield:

```json
[
    [
        {
            "sourceType": "PrivateLoadBalancer",
            "type": "IPAddress",
            "value": "172.18.128.1"
        },
        {
            "sourceType": "PrivateIP",
            "type": "IPAddress",
            "value": "10.96.194.111"
        }
    ]
]
```

## DataPlane proxy service

To get `DataPlane`'s proxy `Service` name you can query the `.status.service` field like so:

```bash
kubectl get -n default dataplane dataplane-example -o jsonpath-as-json='{.status.service}'
```

```yaml
[
    "dataplane-ingress-dataplane-example-sj54n"
]
```

## Troubleshooting using status condition

If your `DataPlane` doesn't work, you can investigate its `.status.conditions` field.

```bash
kubectl get -n default dataplane dataplane-example -o jsonpath-as-json='{.status.conditions}'
```

This can give you insight into the underlying problem:

```json
[
    [
        {
            "lastTransitionTime": "2024-03-22T17:59:13Z",
            "message": "Waiting for the resource to become ready: Deployment dataplane-dataplane-example-bdqjq is not ready yet",
            "observedGeneration": 2,
            "reason": "WaitingToBecomeReady",
            "status": "False",
            "type": "Ready"
        }
    ]
]
```

## Gateway

<!--
Consider adding invocations of gwctl when that becomes stable and provides useful information about the described objects.
https://github.com/kubernetes-sigs/gateway-api/tree/main/gwctl
-->

To retrieve the `status` field of a `Gateway` you can use the following `kubectl` command:

```bash
kubectl get gateway kong -o jsonpath-as-json='{.status}'
```

Which should yield the output similar to the one below:

```json
[
    {
        "addresses": [
            {
                "type": "IPAddress",
                "value": "172.18.128.1"
            }
        ],
        "conditions": [
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "All listeners are accepted.",
                "observedGeneration": 1,
                "reason": "Accepted",
                "status": "True",
                "type": "Accepted"
            },
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "",
                "observedGeneration": 1,
                "reason": "Programmed",
                "status": "True",
                "type": "Programmed"
            },
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "",
                "observedGeneration": 1,
                "reason": "Ready",
                "status": "True",
                "type": "Ready"
            },
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "",
                "observedGeneration": 1,
                "reason": "Ready",
                "status": "True",
                "type": "DataPlaneReady"
            },
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "",
                "observedGeneration": 1,
                "reason": "Ready",
                "status": "True",
                "type": "ControlPlaneReady"
            },
            {
                "lastTransitionTime": "2024-03-22T18:17:00Z",
                "message": "",
                "observedGeneration": 1,
                "reason": "Ready",
                "status": "True",
                "type": "GatewayService"
            }
        ],
        "listeners": [
            {
                "attachedRoutes": 0,
                "conditions": [
                    {
                        "lastTransitionTime": "2024-03-22T18:17:00Z",
                        "message": "",
                        "observedGeneration": 1,
                        "reason": "NoConflicts",
                        "status": "False",
                        "type": "Conflicted"
                    },
                    {
                        "lastTransitionTime": "2024-03-22T18:17:00Z",
                        "message": "",
                        "observedGeneration": 1,
                        "reason": "Accepted",
                        "status": "True",
                        "type": "Accepted"
                    },
                    {
                        "lastTransitionTime": "2024-03-22T18:17:00Z",
                        "message": "",
                        "observedGeneration": 1,
                        "reason": "Programmed",
                        "status": "True",
                        "type": "Programmed"
                    },
                    {
                        "lastTransitionTime": "2024-03-22T18:17:00Z",
                        "message": "Listeners' references are accepted.",
                        "observedGeneration": 1,
                        "reason": "ResolvedRefs",
                        "status": "True",
                        "type": "ResolvedRefs"
                    }
                ],
                "name": "http",
                "supportedKinds": [
                    {
                        "group": "gateway.networking.k8s.io",
                        "kind": "HTTPRoute"
                    }
                ]
            }
        ]
    }
]
```
