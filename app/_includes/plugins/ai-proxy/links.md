{% assign plugin = include.plugin %}
{% assign id = plugin | slugify %}

## Get started
* [Configuration reference](/plugins/{{ id }}/reference/)
* [Configuration examples](/plugins/{{ id }}/examples/)

{% include plugins/ai-plugins.md %}