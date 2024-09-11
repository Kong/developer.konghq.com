<table>
  <thead>
    <tr>
      <th></th>
      {% for c in include.config.columns %}
        <th>
          <span class="font-semibold text-primary">{{ c.title }}</span>
        </th>
      {% endfor %}
    </tr>
  </thead>
  <tbody>
    {% for f in include.config.features %}
      <tr>
        <td>
          <span class="block text-primary">{{ f.title | markdown }}</span>
          {% if f.subtitle %}
          <span class="text-secondary">{{ f.subtitle | markdown }}</span>
          {% endif %}
        </td>
        {% for c in include.config.columns %}
        {% assign v = f[c.key] %}
        <td class="text-center">
        {% if v %}<i class="fa fa-xs fa-check text-primary"></i>{% else %}<i class="fa fa-times text-semantic-red-primary"></i>{% endif %}
        </td>
        {% endfor %}
      </tr>
    {% endfor %}
  </tbody>
</table>
