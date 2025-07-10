Use `uuidgen` to generate a provision key for the OAuth 2.0 Authentication plugin:

{% env_variables %}
DECK_PROVISION_KEY: $(uuidgen)
{% endenv_variables %}