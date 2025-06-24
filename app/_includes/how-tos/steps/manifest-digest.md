Parse the manifest digest for the image using `regctl`, substituting the {{site.ee_product_name}} image you need to verify:

```sh
regctl manifest digest kong/kong-gateway:3.10.0.0
```

The command will output a `SHA-256` digest:

```sh
sha256:ad58cd7175a0571b1e7c226f88ade0164e5fd50b12f4da8d373e0acc82547495
```
{:.no-copy-code}