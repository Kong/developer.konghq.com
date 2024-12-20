<table>
  <thead>
    <tr>
      <th></th>
      {% for c in include.config.columns %}
        <th class="text-center">
          <span class="font-semibold text-primary">{{ c.title | liquify }}</span>
        </th>
      {% endfor %}
    </tr>
  </thead>
  <tbody>
    {% for f in include.config.features %}
      <tr>
        <td>
          <span class="block text-primary">{{ f.title | liquify | markdown }}</span>
          {% if f.subtitle %}
          <span class="text-secondary">{{ f.subtitle | liquify | markdown }}</span>
          {% endif %}
        </td>
        {% for c in include.config.columns %}
        {% assign v = f[c.key] %}
        <td class="text-center">
        {% if v %}{% include icon_true.html %}{% else %}{% include icon_false.html %}{% endif %}
        </td>
        {% endfor %}
      </tr>
    {% endfor %}
  </tbody>
</table>
