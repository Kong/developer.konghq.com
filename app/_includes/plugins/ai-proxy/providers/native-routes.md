{% assign provider = include.providers.providers | where: "name", include.provider_name | first %}

{% if provider %}

{% if provider.native_formats %}

## Supported native LLM formats for {{ provider.name }}

By default, the AI Proxy plugin uses OpenAI-compatible request formats. Set `config.llm_format` to a native format to use {{ provider.name }}-specific APIs and features.

The following native {{ provider.name }} APIs are supported:

{% table %}
columns:
  - title: LLM format
    key: llm_format
  - title: Supported APIs
    key: supported_apis
rows:
{% for format in provider.native_formats %}
  - llm_format: "`{{ format.llm_format }}`"
    supported_apis: |
{% for api in format.supported_apis %}      - `{{ api }}`
{% endfor %}
{% endfor %}
{% endtable %}
{% endif %}

{% if provider.limitations.provider_specific.size > 0 or provider.limitations.statistics_logging.size > 0 %}

{% if provider.limitations.provider_specific.size > 0 %}

### Provider-specific limitations for native formats

{% for limitation in provider.limitations.provider_specific %}
- {{ limitation }}
{% endfor %}
{% endif %}

{% if provider.limitations.statistics_logging.size > 0 %}

### Statistics logging limitations for native formats

{% for limitation in provider.limitations.statistics_logging %}
- {{ limitation }}
{% endfor %}
{% endif %}
{% endif %}

{% endif %}
