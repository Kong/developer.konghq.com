Yes, if {{site.ai_gateway}} is running on Azure, you can configure an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) to detect the designated Managed Identity or User-Assigned Identity of that Azure Compute resource and use it for authentication.

In your [AI Model Provider](/ai-gateway/entities/ai-model-provider/) configuration, set `auth.type` to `azure`, then:
* Set `auth.use_managed_identity` to `true` to use a system-assigned Managed Identity.
* Set `auth.use_managed_identity` to `true` and `auth.client_id` to the client ID to use a user-assigned identity.

Then reference this [AI Model Provider](/ai-gateway/entities/ai-model-provider/) in your [AI Model](/ai-gateway/entities/ai-model/) to proxy requests with the appropriate Azure credentials.
