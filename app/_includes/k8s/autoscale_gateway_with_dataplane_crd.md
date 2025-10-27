## Create a DataPlane with horizontal autoscaling enabled

To enable horizontal autoscaling, you must specify the `spec.deployment.scaling` section in your `DataPlane` resource to indicate which metrics should be used for decision making.

In the example below autoscaling is triggered based on CPU utilization. The `DataPlane` resource can have between 2 and 10 replicas, and a new replica will be launched whenever CPU utilization is above 50%.

The `scaleUp` configuration states that either 100% of existing replicas, or 5 new pods (whichever is higher) may be launched every 10 seconds. If you have 3 replicas, 5 pods may be created. If you have 50 replicas, up to 50 more pods may be launched.

The `scaleDown` configuration states that 100% of pods may be removed (with a `minReplicas` value of 2).

```yaml
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: horizontal-autoscaling
  namespace: kong
spec:
  deployment:
    scaling:
      horizontal:
        minReplicas: 2
        maxReplicas: 10
        metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 50
        behavior:
          scaleUp:
            stabilizationWindowSeconds: 1
            policies:
            - type: Percent
              value: 100
              periodSeconds: 10
            - type: Pods
              value: 5
              periodSeconds: 10
            selectPolicy: Max
          scaleDown:
            stabilizationWindowSeconds: 1
            policies:
            - type: Percent
              value: 100
              periodSeconds: 10
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "1024Mi"
              cpu: "1000m"
          # Add any Konnect-related configuration here: environment variables, volumes, and so on.
' | kubectl apply -f -
```

{:.info}
> See the [CRD reference](/operator/reference/custom-resources/) for all scaling options.

A `DataPlane` is created when the manifest above is applied. This creates 2 `Pod`s running {{site.base_gateway}}, as well as a `HorizontalPodAutoscaler` which will manage the replica count of those `Pod`s to ensure that the average CPU utilization is around 50%.

```bash
kubectl get hpa -n kong
```

The output will show the `HorizontalPodAutoscaler` resource:

```bash
NAME                     REFERENCE                                           TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontal-autoscaling   Deployment/dataplane-horizontal-autoscaling-4q72p   2%/50%    2         10        2          30s
```
{:.no-copy-code}

## Test autoscaling with a load test

You can test if the autoscaling works by using a load testing tool (e.g. k6s) to generate traffic.

1. Fetch the DataPlane address and store it in the `PROXY_IP` variable:

    ```bash
    export PROXY_IP=$(kubectl get -n kong dataplanes.gateway-operator.konghq.com -o jsonpath='{.status.addresses[0].value}' horizontal-autoscaling)
    ```

1. Install [`k6s`](https://k6.io/), then create a configuration file containing the following code:

    ```javascript
    echo '
    import http from "k6/http";
    import { check } from "k6";

    export const options = {
      insecureSkipTLSVerify: true,
      stages: [
        { duration: "120s", target: 5 },
      ],
    };

    // Simulated user behavior
    export default function () {
      let res = http.get(`https://${__ENV.PROXY_IP}`);
      check(res, { "status was 404": (r) => r.status == 404 });
    }
    ' > k6.js
    ```

1. Start the load test:

   ```
   k6 run k6.js
   ```

1. Observe the scaling events in the cluster while the test is running:

    ```bash
    kubectl get events -n kong --field-selector involvedObject.name=horizontal-autoscaling --field-selector involvedObject.kind=HorizontalPodAutoscaler --field-selector='reason=SuccessfulRescale' -w
    ```

    The output will show the scaling events:
    ```bash
    LAST SEEN   TYPE      REASON                         OBJECT                                           MESSAGE
    3m55s       Normal    SuccessfulRescale              horizontalpodautoscaler/horizontal-autoscaling   New size: 6; reason: cpu resource utilization (percentage of request) above target
    3m25s       Normal    SuccessfulRescale              horizontalpodautoscaler/horizontal-autoscaling   New size: 7; reason: cpu resource utilization (percentage of request) above target
    2m55s       Normal    SuccessfulRescale              horizontalpodautoscaler/horizontal-autoscaling   New size: 10; reason: cpu resource utilization (percentage of request) above target
    85s         Normal    SuccessfulRescale              horizontalpodautoscaler/horizontal-autoscaling   New size: 2; reason: All metrics below target
    ```
    {:.no-copy-code}

    The `DataPlane`'s `status` field will also be updated with the number of ready/target replicas:

    ```bash
    kubectl get -n kong dataplanes.gateway-operator.konghq.com horizontal-autoscaling -o jsonpath-as-json='{.status}'
    ```

    ```json
    [
        {
            ...
            "readyReplicas": 2,
            "replicas": 2,
            ...
        }
    ]
    ```
    {:.no-copy-code}
