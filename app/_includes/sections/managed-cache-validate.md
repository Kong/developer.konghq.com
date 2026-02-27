Verify that the Rate Limiting Advanced plugin is using the managed cache partial configuration:
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins
status_code: 200
method: GET
region: global
{% endkonnect_api_request %}
<!--vale on-->

In the response, locate your `rate-limiting-advanced` plugin and confirm that `config.strategy` is set to `redis` and that the partials array contains your managed Redis partial:

```sh
"partials": [
    {
      "id": "dcf411a3-475b-4212-bdf8-ae2b4dfa0a04",
      "name": "konnect-managed",
      "path": "config.redis"
    }
  ]
```
{:.no-copy-code}