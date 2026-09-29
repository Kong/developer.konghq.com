<!--vale off-->
{% assign provider = include.providers.providers | where: "name", include.provider_name | first %}
{%- assign compare_provider = nil -%}
{%- assign compare_provider_specific_size = 0 -%}
{%- assign compare_statistics_size = 0 -%}
{%- if include.compare_provider_name -%}
  {%- assign compare_provider = include.providers.providers | where: "name", include.compare_provider_name | first -%}
  {%- assign compare_provider_specific_size = compare_provider.limitations.provider_specific.size -%}
  {%- assign compare_statistics_size = compare_provider.limitations.statistics_logging.size -%}
{%- endif -%}

{% if provider %}

{% if provider.native_formats %}

## Supported native LLM formats for {{ provider.name }}

By default, {{site.ai_gateway}} uses OpenAI-compatible request formats. Configure a native format in your [AI Model](/ai-gateway/entities/ai-model/) to use {{ provider.name }}-specific APIs and features.

The following native {{ provider.name }} formats are supported:

{% table %}
columns:
  - title: LLM format
    key: llm_format
{% if compare_provider %}
  - title: Variant
    key: variant
{% endif %}
  - title: Supported APIs
    key: supported_apis
rows:
{% for format in provider.native_formats %}
  - llm_format: "`{{ format.llm_format }}`"
{% if compare_provider %}
    variant: "{{ include.variant_label }}"
{% endif %}
    supported_apis: |
{% for api in format.supported_apis %}      - `{{ api }}`
{% endfor %}
{% endfor %}
{% if compare_provider %}
{% for format in compare_provider.native_formats %}
  - llm_format: "`{{ format.llm_format }}`"
    variant: "{{ include.compare_variant_label }}"
    supported_apis: |
{% for api in format.supported_apis %}      - `{{ api }}`
{% endfor %}
{% endfor %}
{% endif %}
{% endtable %}
{% endif %}

{%- assign total_provider_specific = provider.limitations.provider_specific.size | plus: compare_provider_specific_size -%}
{%- assign total_statistics = provider.limitations.statistics_logging.size | plus: compare_statistics_size -%}

{% if total_provider_specific > 0 or total_statistics > 0 %}

{% if total_provider_specific > 0 %}

### Provider-specific limitations for native formats

{% if compare_provider %}
**{{ include.variant_label }}:**

{% for limitation in provider.limitations.provider_specific %}
- {{ limitation }}
{% endfor %}
{% if provider.limitations.provider_specific.size == 0 %}
- None.
{% endif %}

**{{ include.compare_variant_label }}:**

{% for limitation in compare_provider.limitations.provider_specific %}
- {{ limitation }}
{% endfor %}
{% if compare_provider_specific_size == 0 %}
- None.
{% endif %}
{% else %}
{% for limitation in provider.limitations.provider_specific %}
- {{ limitation }}
{% endfor %}
{% endif %}
{% endif %}

{% if total_statistics > 0 %}

### Statistics logging limitations for native formats

{% if compare_provider %}
**{{ include.variant_label }}:**

{% for limitation in provider.limitations.statistics_logging %}
- {{ limitation }}
{% endfor %}
{% if provider.limitations.statistics_logging.size == 0 %}
- None.
{% endif %}

**{{ include.compare_variant_label }}:**

{% for limitation in compare_provider.limitations.statistics_logging %}
- {{ limitation }}
{% endfor %}
{% if compare_statistics_size == 0 %}
- None.
{% endif %}
{% else %}
{% for limitation in provider.limitations.statistics_logging %}
- {{ limitation }}
{% endfor %}
{% endif %}
{% endif %}
{% endif %}

{% endif %}
<!--vale on-->
