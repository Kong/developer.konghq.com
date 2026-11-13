Delete the test namespace:

```sh
kubectl delete namespace kong-mesh-demo
```

Uninstall the zone release:

```sh
helm uninstall kong-mesh --namespace kong-mesh-system
```

Delete the zone namespace and the `cp-token` Secret in it:

```sh
kubectl delete namespace kong-mesh-system
```
