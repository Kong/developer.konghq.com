{% assign prereq = include.prereq %}
<details class="mb-2" markdown="1">
  <summary class="rounded mb-0.5 bg-gray-200 p-2">{{ include.prereq.title | liquify }}</summary>

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
