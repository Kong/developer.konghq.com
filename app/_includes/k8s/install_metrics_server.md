{:.warning}
> In order to be able to use `HorizontalPodAutoscaler` in your clusters you'll need to have a [metrics server](https://github.com/kubernetes-sigs/metrics-server) installed.
> More info on the metrics server can be found in [official Kubernetes docs](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/#metrics-server).

To install a metrics server to test, run the following command:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server \
  -n kube-system \
  --type='json' \
  -p='[{
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }]'
```
