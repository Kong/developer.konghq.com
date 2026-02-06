{%- if page.content_type == 'how_to' and page.navigation != empty -%}
## In this Series

* Name: {{page.series.items.first.title | liquify}}
* Part: {{page.series.position}}
* Total parts: {{page.series.items.size}}
* This page covers: {{page.title | liquify}}
{%- if page.navigation.prev -%}
* Previous part: {{page.navigation.prev.title | liquify}}
{%- endif -%}
{%- if page.navigation.next -%}
* Next part: {{page.navigation.next.title | liquify}}
{%- endif -%}
{%- endif -%}