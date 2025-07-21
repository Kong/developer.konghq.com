Update the Control Plane using the `/declarative-config` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: "/v2/control-planes/$KONNECT_CONTROL_PLANE_ID/declarative-config"
status_code: 201
method: PUT
body_cmd: "$(jq -Rs '{config: .}' < knep-config.yaml)"
{% endkonnect_api_request %}
<!--vale on-->

Restart your data plane to apply the configuration:
```sh
docker restart knep
```
This might take a few seconds.