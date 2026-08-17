{%- capture env_exports -%}
{% if include.config.disable_experimental_betas -%}
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
{% endif -%}
{% if include.config.base_url -%}
export ANTHROPIC_BASE_URL={{include.config.base_url}}
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