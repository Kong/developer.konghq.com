Run the following command to create a demo {{site.mesh_product_name}} deployment:
```sh
helm upgrade \
  --install \
  --create-namespace \
  --namespace kuma-system \
  kuma kuma/kuma
kubectl wait -n kuma-system --for=condition=ready pod --selector=app=kuma-control-plane --timeout=90s
kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/refs/heads/main/k8s/001-with-mtls.yaml
```