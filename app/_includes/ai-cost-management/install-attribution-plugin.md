The attribution plugin captures `ai-cost-` prefixed request headers as tags on usage events.
{{site.konnect_short_name}} applies the plugin to all requests proxied through a specific {{site.ai_gateway}}.

Install the plugin with its default configuration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/ai-gateways/$AI_GATEWAY_ID/attribution-plugin
method: PUT
status_code: 201
body:
  integrations: []
  headers: []
  prefixes: []
  operator_tags: {}
{% endkonnect_api_request %}
<!--vale on-->

Leaving `integrations`, `headers`, and `prefixes` empty means the plugin applies to every request and reads only the default `ai-cost-` headers.

See [Tags and headers](/ai-cost-management/attribution/#tags-and-headers) for the standard tag keys, and [Attribution integrations](/ai-cost-management/integrations/) for tools that send tags automatically.
