## Create the `kong` namespace

Create the `kong` namespace in your Kubernetes cluster, which is where the demo will run:

```sh
kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
```
{: data-test-step="block" }