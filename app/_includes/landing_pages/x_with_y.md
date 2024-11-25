<div class="flex flex-col">
  <div class="grid grid-cols-2 gap-4">
    {% for header in include.config.headers %}
      <h3>{{ header | liquify }}</h3>
    {% endfor %}
  </div>
  {% for item in include.config.items %}
    <div class="grid grid-cols-2 gap-4 items-center py-3 {% if include.config.border %} border-b border-primary/5 {% endif %}">
      <div>{{ item.text | liquify | markdownify }}</div>
      <div>
        {% assign include_path = "landing_pages/" | append: item.action.type | append : ".md" %}
        {% include {{ include_path }} type=item.action.type config=item.action.config %}
      </div>
    </div>
  {% endfor %}
</div>
