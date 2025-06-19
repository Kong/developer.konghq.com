Use `uuidgen` to generate a provision key for the OAuth 2.0 Authentication plugin:

{% validation env-variables %}
DECK_PROVISION_KEY: $(uuidgen)
{% endvalidation %}