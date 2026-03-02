{% assign summary='Azure configuration' %}
{%- capture details_content -%}
{% if config.secret %}
This example requires a few Azure resources. You need an Azure subscription and permissions to create or access these resources:

- A [registered application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate) to use for authentication.
- A [key vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) with at least one [secret](https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-portal). Make sure that your application has access to the key vault.

In this example, the key vault is named `my-example-vault` and contains a secret named `token` whose value is a Bearer token.
{% endif %}

Once the resources are created, you'll need the following credentials to connect {{site.base_gateway}} to Azure:
- Your application's client ID
- Your application's client secret
- Your Azure tenant ID
- You Azure location, `eastus` in this example
{% if config.secret %}
- Your vault URI, `https://my-example-vault.vault.azure.net/` in this example
{% endif %}
      
Set the environment variables needed to authenticate to Azure:
```sh
export AZURE_CLIENT_SECRET='YOUR AZURE APPLICATION CLIENT SECRET'
```

Note that the `AZURE_CLIENT_SECRET` variable needs to be passed when creating your Data Plane container.
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/azure.svg' %}