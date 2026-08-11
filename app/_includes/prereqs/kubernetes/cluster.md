You need a running Kubernetes cluster with `kubectl` configured to point at it. Any cluster works, whether it runs locally or in a cloud provider.

If you don't have one, create a local cluster with [minikube](https://minikube.sigs.k8s.io/docs/):

```sh
minikube start -p kong-demo
```