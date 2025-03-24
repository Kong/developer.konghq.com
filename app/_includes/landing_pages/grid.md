{% assign tag = "div" %}
{% if include.tag %}
{% assign tag = include.tag %}
{% endif %}

{% assign gap = "2" %}
{% if include.gap %}
{% assign gap = include.gap %}
{% endif %}

{% assign rows = include.rows %}
{% if include.config.rows %}
{% assign rows = include.config.rows %}
{% endif %}

<{{ tag }} class="flex flex-col gap-3 w-full">
  <div class="flex flex-col gap-{{ gap }}">
    {% for row in rows %}

        {% assign h2_col = row.columns | find_exp: "col", "col.header and col.header.type =='h2'" %}
        <div class="grid gap-4 {% unless h2_col %}heading-section{% endunless %}">
          {% if row.header %}
              {% include landing_pages/header.md config = row.header %}
          {% endif %}

          {% if row.columns %}
            {% assign column_count =  row.columns | size %}
            {% if row.column_count %}
              {% assign column_count = row.column_count %}
            {% endif %}
            <div class="grid grid-cols-1 lg:grid-cols-{{ column_count }} gap-8">
              {% for column in row.columns %}
                <div class="flex flex-col gap-3 {% if column.col_span %}col-span-{{ column.col_span }} {% endif %}{% if column.header and column.header.type == 'h2' %} heading-section {% endif %}">
                  {% if column.header %}
                  {% include landing_pages/header.md config = column.header %}
                  {% endif %}

                  {% for entry in column.blocks %}
                      {% assign include_path = "landing_pages/" | append: entry.type | append : ".md" %}
                      {% capture include_template %}{% include {{ include_path }} type=entry.type config=entry.config %}{% endcapture %}
                      {{ include_template | markdownify }}
                  {% endfor %}
                </div>
              {% endfor %}
            </div>
          {% endif %}
        </div>

    {% endfor %}
  </div>
</{{ tag }}>
