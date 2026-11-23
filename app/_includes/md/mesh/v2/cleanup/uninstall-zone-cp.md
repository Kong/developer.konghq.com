Uninstall {{site.mesh_product_name}} and remove its namespace:

```sh
helm uninstall kong-mesh --namespace kong-mesh-system
kubectl delete namespace kong-mesh-system
```
