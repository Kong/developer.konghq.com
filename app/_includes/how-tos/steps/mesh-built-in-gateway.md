<!--
Used in:
- app/_how-tos/set-up-a-built-in-kubernetes-gateway.md
- app/_how-tos/set-up-a-built-in-mesh-gateway.md
-->

{% capture intro %}
To get traffic from outside your mesh with {{site.mesh_product_name}}, you can use a built-in gateway.

With the [demo configuration](#install-kong-mesh-with-demo-configuration), traffic can only get in the mesh by port-forwarding to an instance of an app inside the mesh.
In production, you typically set up a gateway to receive traffic external to the mesh.
{% endcapture %}

{% capture ip %}
1. Export the gateway's public IP: 

   ```sh
   export PROXY_IP=$(kubectl get svc -n kong-mesh-demo built-in-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo $PROXY_IP
   ```

1. Send a request to the gateway to validate that it's running:

   ```sh
   curl -i $PROXY_IP:8080
   ```
   
   Since we haven't configured any Routes, you should see the following result:

   ```sh
   HTTP/1.1 404 Not Found
   content-length: 62
   content-type: text/plain
   vary: Accept-Encoding
   date: Tue, 06 Jan 2026 14:36:29 GMT
   server: Kuma Gateway
   
   This is a Kuma MeshGateway. No routes match this MeshGateway!
   ```
   {:.no-copy-code}
{% endcapture %}

{% capture rbac %}
1. Send a request to the gateway:

   ```sh
   curl -i $PROXY_IP:8080
   ```

   Now the Route exists, but the gateway can't access the demo app service because of the permissions applied in the [demo configuration](#install-kong-mesh-with-demo-configuration):   
   ```sh
   HTTP/1.1 403 Forbidden
   content-length: 19
   content-type: text/plain
   date: Tue, 06 Jan 2026 14:37:19 GMT
   server: Kuma Gateway
   x-envoy-upstream-service-time: 0
   
   RBAC: access denied%      
   ```
   {:.no-copy-code}
{% endcapture %}

{% capture traffic %}
1. Add a `MeshTrafficPermission` resource to allow traffic to the service:
   
   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     namespace: kong-mesh-demo 
     name: demo-app
   spec:
     targetRef:
       kind: Dataplane
       labels:
         app: demo-app
     from:
       - targetRef:
           kind: MeshSubset
           tags: 
             kuma.io/service: built-in-gateway_kong-mesh-demo_svc 
         default:
           action: Allow" | kubectl apply -f -
   ```
   
1. Send a request to the Route:

   ```sh
   curl -XPOST -i $PROXY_IP:8080/api/counter
   ```

   You should get the following result:
   
   ```json
   {"counter":1,"zone":""}
   ```
   {:.no-copy-code}
{% endcapture %}

{% capture cert %}
With the gateway, we exposed the application to a public endpoint. To secure it, we'll add TLS to our endpoint.

1. Create a self-signed certificate:

   ```sh
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=$PROXY_IP"
   ```
{% endcapture %}

{% capture validate %}
1. Send a request to the gateway:   
   ```sh
   curl -X POST -v --insecure "https://$PROXY_IP:8080/api/counter"
   ```
   
   {:.info}
   > Since we're using a self-signed certificate for testing purposes, we need the `--insecure` flag  .
   
   You should see a successful request with a TLS handshake:

   ```sh
   *   Trying 127.0.0.0:8080...
   * Connected to 127.0.0.0 (127.0.0.0) port 8080
   * ALPN: curl offers h2,http/1.1
   * (304) (OUT), TLS handshake, Client hello (1):
   * (304) (IN), TLS handshake, Server hello (2):
   * (304) (IN), TLS handshake, Unknown (8):
   * (304) (IN), TLS handshake, Certificate (11):
   * (304) (IN), TLS handshake, CERT verify (15):
   * (304) (IN), TLS handshake, Finished (20):
   * (304) (OUT), TLS handshake, Finished (20):
   * SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256 / [blank] / UNDEF
   * ALPN: server accepted h2
   * Server certificate:
   *  subject: CN=127.0.0.0
   *  start date: Jan  6 14:38:19 2026 GMT
   *  expire date: Jan  6 14:38:19 2027 GMT
   *  issuer: CN=127.0.0.0
   *  SSL certificate verify result: self signed certificate (18), continuing anyway.
   * using HTTP/2
   * [HTTP/2] [1] OPENED stream for https://127.0.0.0:8080/api/counter
   * [HTTP/2] [1] [:method: POST]
   * [HTTP/2] [1] [:scheme: https]
   * [HTTP/2] [1] [:authority: 127.0.0.0:8080]
   * [HTTP/2] [1] [:path: /api/counter]
   * [HTTP/2] [1] [user-agent: curl/8.7.1]
   * [HTTP/2] [1] [accept: */*]
   > POST /api/counter HTTP/2
   > Host: 127.0.0.0:8080
   > User-Agent: curl/8.7.1
   > Accept: */*
   > 
   * Request completely sent off
   < HTTP/2 200 
   < content-type: application/json; charset=utf-8
   < x-demo-app-version: v1
   < date: Tue, 06 Jan 2026 15:01:35 GMT
   < content-length: 24
   < x-envoy-upstream-service-time: 25
   < server: Kuma Gateway
   < strict-transport-security: max-age=31536000; includeSubDomains
   < 
   {"counter":2,"zone":""}
   ```
   {:.no-copy-code}
{% endcapture %}

{% if include.section == "intro" %}
{{intro}}
{% endif %}

{% if include.section == "ip" %}
{{ip}}
{% endif %}

{% if include.section == "rbac" %}
{{rbac}}
{% endif %}

{% if include.section == "traffic" %}
{{traffic}}
{% endif %}

{% if include.section == "cert" %}
{{cert}}
{% endif %}

{% if include.section == "validate" %}
{{validate}}
{% endif %}