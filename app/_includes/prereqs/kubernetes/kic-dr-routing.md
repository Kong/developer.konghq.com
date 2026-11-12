In production, these manifests live in your deployment repository and the certificate lives in your secret store.
In this guide, a local `recovery` directory plays that role.

1. Create the directory:

   ```bash
   mkdir -p recovery
   ```

1. Create a self-signed certificate for `echo.example.com`:

   ```bash
   openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
     -keyout recovery/tls.key -out recovery/tls.crt \
     -subj "/CN=echo.example.com" -addext "subjectAltName=DNS:echo.example.com"
   ```

1. Store the certificate in a TLS Secret named `echo-tls`:

   ```bash
   kubectl create secret tls echo-tls -n kong \
     --cert=recovery/tls.crt --key=recovery/tls.key
   ```

1. Save an Ingress that routes `echo.example.com/echo` to the echo Service over HTTPS:

   ```bash
   cat <<EOF > recovery/resources.yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: echo
     namespace: kong
   spec:
     ingressClassName: kong
     tls:
       - hosts:
           - echo.example.com
         secretName: echo-tls
     rules:
       - host: echo.example.com
         http:
           paths:
             - path: /echo
               pathType: Prefix
               backend:
                 service:
                   name: echo
                   port:
                     number: 1027
   ---
   EOF
   ```

1. Add the echo application to the same manifest:

   ```bash
   curl -fsSL {{site.links.web}}/manifests/kic/echo-service.yaml >> recovery/resources.yaml
   ```

1. Apply the manifest:

   ```bash
   kubectl apply -n kong -f recovery/resources.yaml
   ```

1. Wait for the echo application:

   ```bash
   kubectl rollout status deployment/echo -n kong --timeout=300s
   ```
