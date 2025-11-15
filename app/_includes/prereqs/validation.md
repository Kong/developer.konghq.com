{% capture summary %}{{include.validation.title}}{% endcapture %}
{% capture details_content %}
```sh
{{include.validation.command | rstrip}}
```

{{include.validation.message}}
{% endcapture %}

{% assign icon_url = "/assets/icons/code.svg" %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}