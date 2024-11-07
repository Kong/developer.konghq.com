<table>
  <thead>
    <tr>
      <th></th>
      {% for c in include.config.columns %}
        <th class="text-center">
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
        {% if v %}<span class="inline-flex text-terciary w-5 h-5">{% include_svg '/assets/icons/check.svg' %}</span>{% else %}<span class="inline-flex text-semantic-red-primary w-5 h-5">{% include_svg '/assets/icons/close.svg' %}</span>{% endif %}
        </td>
        {% endfor %}
      </tr>
    {% endfor %}
  </tbody>
</table>
