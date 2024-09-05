<ul class="list-disc list-inside">
  {% for list_item in include.config.items %}
    <li>
      {% for badge in list_item.badges %}
        <span class="bg-blue-200 text-blue-800 text-xs font-semibold px-2 py-1 rounded-full mr-0.5">{{ badge }}</span>
      {% endfor %}
      {{ list_item.text | markdown }}
    </li>
  {% endfor %}
</ul>
