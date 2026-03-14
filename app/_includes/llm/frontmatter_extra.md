{% if page.content_type == 'how_to' and page.series -%}
  {%- assign series_meta = site.data.series[page.series.id] -%}
series:
  title: "{{ series_meta.title | liquify }}"
  position: {{ page.series.position }}
  total: {{ page.series.items.size }}
  {%- if page.navigation.prev %}
  prev:
    title: "{{ page.navigation.prev.title | liquify }}"
    url: "{{ page.navigation.prev.url }}"
  {%- endif %}
  {%- if page.navigation.next %}
  next:
    title: "{{ page.navigation.next.title | liquify }}"
    url: "{{ page.navigation.next.url }}"
  {%- endif %}
{% endif -%}
