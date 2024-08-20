{% assign step = include.step %}
<details class="mb-2" markdown="1">
  <summary class="rounded mb-0.5 bg-gray-200 p-2">{{ include.step.title | liquify }}</summary>

  {% if step.content %}
  {{ include.step.content | liquify | markdownify }}
  {% elsif step.include_content %}
  {% assign include_path = step.include_content | append: ".md" %}
  {% capture included_content %}{% include {{ include_path }} %}{% endcapture %}
  {{ included_content | liquify | markdownify }}
  {% else %}
      {% raise "content or include_content must be set when using the `cleanup.inline` block" %}
  {% endif %}

</details>
