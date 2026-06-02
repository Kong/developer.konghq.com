Starting with decK {% new_in 1.59 %} in order to avoid regenerating session credentials during sync, you need to set [`cache_tokens_salt`](/plugins/openid-connect/reference/#schema--config-cache-tokens-salt). Generate a salt token:

{% env_variables %}
DECK_TOKEN_SALT: $(openssl rand -base64 16)
{% endenv_variables %}