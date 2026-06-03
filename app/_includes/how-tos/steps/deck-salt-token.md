Starting with decK {% new_in 1.59 %}, you need to set [`cache_tokens_salt`](/plugins/openid-connect/reference/#schema--config-cache-tokens-salt) to avoid regenerating session credentials during sync. Generate a salt token:

{% env_variables %}
DECK_TOKEN_SALT: $(openssl rand -base64 16)
{% endenv_variables %}