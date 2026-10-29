{%- if example.data.global == false -%}
{%- assign scope = include.targets[example.target.key] -%}
After creating the policy, add `{{ example.data.name }}` to the `policies` array of your [{{ scope.label }}]({{ scope.url }}).
{%- endif -%}
