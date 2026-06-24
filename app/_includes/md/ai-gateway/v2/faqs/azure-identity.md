Yes, if {{site.base_gateway}} is running on Azure, you can configure an [AI Provider](/ai-gateway/entities/ai-provider/) to detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource and use it for authentication.

In your [AI Provider](/ai-gateway/entities/ai-provider/) configuration:
* Set `auth.azure_use_managed_identity` to `true` to use an Azure-Assigned Managed Identity.
* Set `auth.azure_use_managed_identity` to `true` and `auth.azure_client_id` to the client ID to use a User-Assigned Identity.

Then reference this [AI Provider](/ai-gateway/entities/ai-provider/) in your [AI Model](/ai-gateway/entities/ai-model/) to proxy requests with the appropriate Azure credentials.
