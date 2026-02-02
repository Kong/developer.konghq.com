{% for next_step in next_steps.items %}
- [{{next_step.text | liquify}}]({{next_step.url | liquify}})
{% endfor %}