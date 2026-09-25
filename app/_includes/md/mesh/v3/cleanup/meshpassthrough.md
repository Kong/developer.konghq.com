If you followed the guide in order you already deleted `allow-all-passthrough` and `secure-perimeter`. Delete whichever policies remain:

```sh
kubectl delete meshpassthrough allow-all-passthrough secure-perimeter selective-passthrough -n kong-air-production --ignore-not-found
```

Confirm the perimeter is open again. With no `MeshPassthrough` policy in place, the `Mesh` controls passthrough through `networking.outbound.passthrough`, which is `true` when unset:

```sh
kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.bing.com
```

The command prints the response body again, as it did before you started.
