<ul>
  {% for item in include.config %}
    <li>
      This will show references tagged with '{{ item.topic }}'{% if item.product %} in the '{{ item.product }}' product{% endif %}
    </li>
  {% endfor %}
</ul>