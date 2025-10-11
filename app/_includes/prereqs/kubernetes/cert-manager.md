1. Create the `kong` namespace
    
    ```sh
    kubectl create namespace kong
    ```
1. Install cert-manager

    ```
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.crds.yaml
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
    kubectl -n cert-manager get pods
    ```

1. Create an Issuer

    ```bash
    echo '
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: example-issuer
      namespace: cert-manager
    spec:
      selfSigned: {}
    ' | kubectl apply -f -
    ```

1. Create a Certificate

```bash
echo '
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-cert
  namespace: cert-manager
spec:
  secretName: example-cert-tls
  issuerRef:
    name: example-issuer
    kind: Issuer
  dnsNames:
    - example.com
' | kubectl apply -f -

```