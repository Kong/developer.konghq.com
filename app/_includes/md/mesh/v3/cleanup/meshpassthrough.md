If you followed the guide in order, you already deleted `allow-all-passthrough` and `secure-perimeter`.
Delete the policies that remain:

```sh
kubectl delete meshpassthrough allow-all-passthrough secure-perimeter selective-passthrough -n kong-air-production --ignore-not-found
```

Confirm that the perimeter is open again.
The Kong Air control plane sets `restrictOutbound` to `false`, so with no `MeshPassthrough` policy in place, `check-in-api` reaches any destination:

```sh
kubectl exec -n kong-air-production deploy/check-in-api -- wget -q -T 5 -O- http://www.bing.com
```

The command prints the response body.
