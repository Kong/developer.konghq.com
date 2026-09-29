{%- if config.status_code and config.message -%}
This request returns a `{{ config.status_code }}` error with the message `{{ config.message }}`.
{%- elsif config.status_code -%}
This request returns a `{{ config.status_code }}` error.
{%- elsif config.message -%}
This request returns an error with the message `{{ config.message }}`.
{%- endif -%}
