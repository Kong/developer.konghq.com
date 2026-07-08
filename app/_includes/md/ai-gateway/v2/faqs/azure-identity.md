Yes, if {{site.ai_gateway}} is running on Azure, you can configure an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) to detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource and use it for authentication.

In your [AI Model Provider](/ai-gateway/entities/ai-model-provider/) configuration:
* Set `auth.azure_use_managed_identity` to `true` to use an Azure-Assigned Managed Identity.
* Set `auth.azure_use_managed_identity` to `true` and `auth.azure_client_id` to the client ID to use a User-Assigned Identity.

Then reference this [AI Model Provider](/ai-gateway/entities/ai-model-provider/) in your [AI Model](/ai-gateway/entities/ai-model/) to proxy requests with the appropriate Azure credentials.
