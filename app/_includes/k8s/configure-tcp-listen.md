
## Expose additional ports

{{site.base_gateway}} does not include any TCP listen configuration by default. To expose TCP listens, update the Deployment's environment variables and port configuration.

1. Update the Deployment.
    ```bash
    kubectl patch deploy -n kong kong-gateway --patch '{
      "spec": {
        "template": {
          "spec": {
            "containers": [
              {
                "name": "proxy",
                "env": [
                  {
                    "name": "KONG_STREAM_LISTEN",
                    "value": "{% if include.plaintext %}0.0.0.0:9000{% endif %}{% if include.plaintext and include.tls %}, {% endif %}{% if include.tls %}0.0.0.0:9443 ssl{% endif %}"
                  }
                ],
                "ports": [
                  {% if include.plaintext %}{
                    "containerPort": 9000,
                    "name": "stream9000",
                    "protocol": "TCP"
                  }{% endif %}{% if include.plaintext and include.tls %},{% endif %}{% if include.tls %}{
                    "containerPort": 9443,
                    "name": "stream9443",
                    "protocol": "TCP"
                  }{% endif %}
                ]
              }
            ]
          }
        }
      }
    }'
    ```

    The `ssl` parameter after the 9443 listen instructs {{site.base_gateway}} to expect TLS-encrypted TCP traffic on that port. The 9000 listen has no parameters, and expects plain TCP traffic.

1.  Update the proxy Service to indicate the new ports.

    ```bash
    kubectl patch service -n kong kong-gateway-proxy --patch '{
      "spec": {
        "ports": [{% if include.plaintext %}
          {
            "name": "stream9000",
            "port": 9000,
            "protocol": "TCP",
            "targetPort": 9000,
            "allowedRoutes": {
                "namespaces": {
                  "from": "All"
                }
            }
          }{% endif %}{% if include.plaintext and include.tls %},{% endif %}{% if include.tls %}
          {
            "name": "stream9443",
            "port": 9443,
            "protocol": "TCP",
            "targetPort": 9443,
            "allowedRoutes": {
                "namespaces": {
                  "from": "All"
                }
            }
          }{% endif %}
        ]
      }
    }'
    ```