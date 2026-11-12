This guide starts from a data plane that runs in the `kong-dr` cluster and is connected to a {{site.konnect_short_name}} control plane with one Gateway Service and Route.

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   ```

1. Update the Helm repositories:

   ```bash
   helm repo update
   ```

1. Create a [control plane](/gateway/control-plane-groups/) and save its ID and endpoints:

   {% capture create_control_plane %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes
   status_code: 201
   method: POST
   body:
     name: dr-control-plane
   capture:
     - variable: CONTROL_PLANE_ID
       jq: ".id"
     - variable: CONTROL_PLANE_ENDPOINT
       command: jq -r '.config.control_plane_endpoint | sub("https://";"")'
     - variable: CONTROL_PLANE_TELEMETRY
       command: jq -r '.config.telemetry_endpoint | sub("https://";"")'
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_control_plane | indent }}

1. Create a client certificate and key for the data plane:

   ```bash
   openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
     -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
   ```

1. Store the certificate in a variable, in the format that the API expects:

   ```bash
   export CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.crt)
   ```

1. Register the certificate with the control plane:

   {% capture register_certificate %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID/dp-client-certificates
   status_code: 201
   method: POST
   body:
     cert: "$CERT"
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ register_certificate | indent }}

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Store the certificate and key in a Secret:

   ```bash
   kubectl create secret tls kong-cluster-cert -n kong --cert=./tls.crt --key=./tls.key
   ```

1. Create a `values-dp.yaml` file that connects the data plane to the control plane:

   ```bash
   cat <<EOF > values-dp.yaml
   ingressController:
     enabled: false
   image:
     repository: kong/kong-gateway
     tag: "{{ site.data.gateway_latest.release }}"
   secretVolumes:
     - kong-cluster-cert
   env:
     role: data_plane
     database: "off"
     konnect_mode: "on"
     vitals: "off"
     cluster_mtls: pki
     cluster_control_plane: "$CONTROL_PLANE_ENDPOINT:443"
     cluster_server_name: "$CONTROL_PLANE_ENDPOINT"
     cluster_telemetry_endpoint: "$CONTROL_PLANE_TELEMETRY:443"
     cluster_telemetry_server_name: "$CONTROL_PLANE_TELEMETRY"
     cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
     cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key
     lua_ssl_trusted_certificate: system
   proxy:
     enabled: true
   admin:
     enabled: false
   manager:
     enabled: false
   EOF
   ```

1. Install the data plane:

   ```bash
   helm install kong kong/kong -n kong -f values-dp.yaml --wait --timeout 5m
   ```

1. Create a [Gateway Service](/gateway/entities/service/) named `dr-check` that points to an upstream:

   {% capture create_service %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services
   status_code: 201
   method: POST
   body:
     name: dr-check
     url: https://httpbin.konghq.com
   capture:
     - variable: SERVICE_ID
       jq: ".id"
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_service | indent }}

1. Create a [Route](/gateway/entities/route/) named `dr-check` for the `/dr-check` path.
   New Routes accept only HTTPS by default, so set `protocols` to accept HTTP:

   {% capture create_route %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/routes
   status_code: 201
   method: POST
   body:
     name: dr-check
     paths:
       - /dr-check
     protocols:
       - http
     service:
       id: $SERVICE_ID
   capture:
     - variable: ROUTE_ID
       jq: ".id"
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_route | indent }}
