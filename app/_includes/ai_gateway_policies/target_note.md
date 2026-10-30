{%- if example.data.global == false -%}
{%- assign scope = include.targets[example.target.key] -%}
After creating the policy, add `{{ example.data.name }}` to the `policies` array of your [{{ scope.label }}]({{ scope.url }}). The tool examples update an existing {{ scope.label }} with the policy attached: replace the entity configuration in the example with your own, as the update replaces the entire {{ scope.label }}.
{%- endif -%}
