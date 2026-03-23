{% if include.section == "question" %}

Can I authenticate to Azure AI with Azure Identity?

{% elsif include.section == "answer" %}

Yes, if {{site.base_gateway}} is running on Azure, AI Proxy can detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource, and use it accordingly.
In your AI Proxy configuration, set the following parameters:
* [`config.auth.azure_use_managed_identity`](/plugins/ai-proxy/reference/#schema--config-auth-azure-use-managed-identity) to `true` to use an Azure-Assigned Managed Identity.
* [`config.auth.azure_use_managed_identity`](/plugins/ai-proxy/reference/#schema--config-auth-azure-use-managed-identity) to `true` and a [`config.auth.azure_client_id`](/plugins/ai-proxy/reference/#schema--config-auth-azure-client-id) to use a User-Assigned Identity.

{% endif %}
