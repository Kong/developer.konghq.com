{% assign prereq = include.prereq %}
<details class="py-4 px-5 flex flex-col gap-1 bg-secondary shadow-primary rounded-md" markdown="1">
  <summary class="text-sm text-primary list-none">{{ include.prereq.title | liquify }}<span class="fa fa-chevron-down float-right text-terciary"></span></summary>

  {% if prereq.content %}
  {{ include.prereq.content | liquify | markdownify }}
  {% elsif prereq.include_content %}
  {% assign include_path = prereq.include_content | append: ".md" %}
  {% capture included_content %}{% include {{ include_path }} %}{% endcapture %}
  {{ included_content | liquify | markdownify }}
  {% else %}
      {% raise "content or include_content must be set when using the `prereqs.inline` block" %}
  {% endif %}

</details>
