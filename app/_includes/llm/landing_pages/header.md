{%- assign title = include.config.text | liquify -%}
{%- case include.config.type -%}{%- when 'h1' -%}# {{ title }}{%- when 'h2' -%}## {{ title }}{%- when 'h3' -%}### {{ title }}{%- when 'h4' -%}#### {{ title }}{%- when 'h5' -%}##### {{ title }}{%- when 'h6' -%}###### {{ title }}{%- endcase %}

{% if include.config.sub_text -%}{{ include.config.sub_text | liquify }}{%- endif -%}