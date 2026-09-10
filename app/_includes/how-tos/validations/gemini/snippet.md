```sh
{% if include.config.base_url -%}
export GOOGLE_GEMINI_BASE_URL={{include.config.base_url}}

{% endif -%}
{{include.config.base_command}}
```

And ask a question to confirm that requests reach {{site.ai_gateway}}.

```text
{{ include.config.prompt }}
```
