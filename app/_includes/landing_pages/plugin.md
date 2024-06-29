{%- capture plugin_name -%}{% plugin_name include.config.name %}{%- endcapture -%}

<div class="flex mb-2">
<img class="w-6 mr-1" src="https://docs.konghq.com/assets/images/icons/hub/kong-inc_{{ include.config.name }}.png">
<h3 class="text-xl font-bold">{{ plugin_name }}</h3>
</div>
<p>This is some content that will be very long about how great {{ plugin_name }} is</p>
