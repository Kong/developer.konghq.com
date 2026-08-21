{%- capture env_exports -%}
{% if include.config.open_api_key -%}
export OPENAI_API_KEY={{include.config.open_api_key}}
{% endif -%}
{% if include.config.base_url -%}
export OPENAI_BASE_URL={{include.config.base_url}}
{% endif -%}
{%- endcapture -%}
```sh
{% if env_exports != empty -%}
{{ env_exports | strip }}

{% endif -%}
{{include.config.base_command}}
```

And ask a question to confirm that requests reach {{site.ai_gateway}}.

```text
{{ include.config.prompt }}
```
