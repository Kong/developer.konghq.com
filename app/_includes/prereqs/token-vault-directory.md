You must enable [Token Vault](/identity/token-vault/) must on your {{site.identity}} directory. Enable it, or check if it's already enabled.

{% navtabs 'token-vault' %}
{% navtab "Enable Token Vault" %}

Enable the Token Vault on the directory:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: PATCH
body:
  vault_enabled: true
extract_body:
  - name: 'name'
    variable: DIRECTORY_NAME
capture:
  - variable: DIRECTORY_NAME
    jq: ".name"
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Check if already enabled" %}

Look up the directory. If `vault_enabled` is `true`, the Token Vault is already enabled and you can skip enabling it:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: GET
extract_body:
  - name: 'name'
    variable: DIRECTORY_NAME
capture:
  - variable: DIRECTORY_NAME
    jq: ".name"
  - variable: VAULT_ENABLED
    jq: ".vault_enabled"
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}
