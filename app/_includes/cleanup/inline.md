{% assign step = include.step %}
<details class="py-4 px-5 flex flex-col gap-1 bg-secondary shadow-primary rounded-md text-sm" markdown="1">
  <summary class="text-sm text-primary list-none">{{ include.step.title | liquify }}<span class="fa fa-chevron-down float-right text-terciary"></span></summary>

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
