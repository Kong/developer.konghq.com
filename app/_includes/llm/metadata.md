**Metadata**:
{%- if page.products %}
- Products: {{page.llm_metadata.products | join: ', '}}
{%- endif -%}
{%- if page.tier %}
- Tier: {{page.llm_metadata.tier}}
{%- endif -%}
{%- if page.min_version %}
- Min version: {% for min_version in page.min_version %}{% assign product = min_version[0] %}{% assign version = min_version[1] %}
  - {{ site.data.products[product].name }} - {{ version }}{% endfor %}
{%- endif -%}
{%- if page.works_on %}{% assign incompatibilities = page.works_on | works_on_incompatibilities %}{% if incompatibilities.size > 0  %}
- Incompatible with: {{incompatibilities | join: ', '}}
{%- endif %}{% endif -%}
{%- if page.tools %}
- Tools: {{page.llm_metadata.tools | join: ', '}}
{%- endif -%}
{%- if page.publisher %}
- Made by: {{site.data.plugin_publishers[page.publisher].name}}
{%- endif -%}
{%- if page.topologies -%}
{%- if page.topologies.on_prem %}
- Supported Gateway Topologies: {{page.topologies.on_prem | join: ', '}}
{%- endif -%}
{%- if page.topologies.konnect_deployments %}
- Supported Konnect Deployments: {{page.topologies.konnect_deployments | join: ', '}}
{%- endif -%}
{%- endif -%}
{%- if page.compatible_protocols %}
- Compatible Protocols: {{page.compatible_protocols | join: ", "}}
{%- endif -%}

