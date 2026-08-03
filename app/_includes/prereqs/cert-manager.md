Install cert-manager in your cluster to issue and rotate certificates automatically:

```sh
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
kubectl wait -n cert-manager --for=condition=ready pod --all --timeout=90s
```
