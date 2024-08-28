<table>
  <thead>
    <tr>
      <th></th>
      {% for c in include.config.columns %}
        <th>
          <strong>{{ c.title }}</strong>
        </th>
      {% endfor %}
    </tr>
  </thead>
  <tbody>
    {% for f in include.config.features %}
      <tr>
        <td>
          <span class="block">{{ f.title | markdown }}</span>
          {% if f.subtitle %}
          <span class="text-sm text-gray-500">{{ f.subtitle }}</span>
          {% endif %}
        </td>
        {% for c in include.config.columns %}
        {% assign v = f[c.key] %}
        <td>
        {% if v %}✅{% else %}❌{% endif %}
        </td>
        {% endfor %}
      </tr>
    {% endfor %}
  </tbody>
</table>
