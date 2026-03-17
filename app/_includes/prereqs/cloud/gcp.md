{% assign summary='Google Cloud configuration' %}
{%- capture details_content -%}
{%- if config.secret -%}
To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must configure the following:

1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
2. On the [Secret Manager page](https://console.cloud.google.com/security/secret-manager), create a secret called `test-secret` with the following JSON content:

    ```json
    secret
    ```
3. Create a service account key and grant IAM permissions:
    1. In the [Service Account settings](https://console.cloud.google.com/iam-admin/serviceaccounts), click the `test-gateway-vault` project and then click the email address of the service account that you want to create a key for.
    2. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
    3. Save the JSON file you downloaded.
    4. From the [IAM & Admin settings](https://console.cloud.google.com/iam-admin/), click the edit icon next to the service account to grant access to the [`Secret Manager Secret Accessor` role for your service account](https://cloud.google.com/secret-manager/docs/access-secret-version#required_roles).
icon_url: /assets/icons/google-cloud.svg
{% endif %}

Set the environment variables needed to authenticate to Google Cloud:
```sh
export GCP_SERVICE_ACCOUNT=$(cat /path/to/file/service-account.json | jq -c)
export KONG_LUA_SSL_TRUSTED_CERTIFICATE='system'
```

Note that these variables need to be passed when creating your Data Plane container.
{% endcapture %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/google-cloud.svg' %}