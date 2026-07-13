{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'model-provider' %}
The following creates a new AI Model Provider. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Providers**.
1. Click **New Provider**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Select a provider (for example: `{{ include.presenter.data['type'] }}`).
1. Configure authentication and connection settings for the selected provider type.
1. Click **Create**.
{% when 'identity-provider' %}
The following creates a new AI Identity Provider. Suggested values are shown in backticks:

<!-- TODO: verify against screenshot, not yet confirmed against the UI -->

The following creates a new identity provider. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Identity**.
1. Click **New identity provider**.
1. Enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and select a **Type**, either **API key** or **OpenID Connect**.
1. If you selected **API key**, configure the key names and where the key is checked (header, query, or body).
1. If you selected **OpenID Connect**, enter an **Issuer**, **Client ID**, and **Client secret**, and configure the claim used to match requests to a consumer.
1. Click **Create**.
{% when 'policy' %}
The following creates a new AI Policy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Policies**.
1. Click **New Policy**.
1. Enter a **Display Name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Name** (for example: `{{ include.presenter.data['name'] }}`).
1. Select a policy **Type** (for example: `{{ include.presenter.data['type'] }}`).
1. Configure the policy `config` fields.
1. Click **Create**.
{% when 'consumer' %}
The following creates a new AI Consumer. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Consumers**.
1. Click **New consumer**.
1. Select a consumer **Type** (for example: `{{ include.presenter.data['type'] }}`).
1. Enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Custom ID** (for example: `{{ include.presenter.data['custom_id'] }}`).
1. If you selected **API key**, optionally enter a **Display name** for the key and click **Generate key**, then click **Create key**. Click **Skip** instead if you don't want to add a key yet.
1. If you selected **OAuth**, click **Create**. Authentication for this consumer type is handled by an OpenID Connect policy matched to the consumer's Custom ID, not by a key generated here.
{% when 'consumer_group' %}
The following creates a new AI consumer group. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Consumers**.
1. Select the **Groups** tab.
1. Click **New consumer group**.
1. Enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. Optional. Select one or more consumers to add to the group.
1. Click **Create**.
{% when 'model' %}
The following creates a new model. Suggested values are shown in backticks.

The following creates a new model. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Models**.
1. Click **New model**.
1. In **General information**, toggle **Enabled**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`), and select a **Type**, either **Model** for generative and embeddings requests, or **API** for files and batch operations.
1. Optional. Enter a **Model alias** if you plan to route by request body instead of base path or hostname.
1. In **Route**, enter a **Base path** to determine how the AI Gateway is accessed. Don't include capability-specific paths such as `/chat/completions`, those are set in the Capabilities section.
1. In **Target models**, select a **Provider**. If you selected **Model** as the type, also select a **Target model**. Add additional targets to route requests across multiple providers.
1. In **Capabilities**, select which AI capabilities this model supports. For **Model** type, options include Chat completions, Embeddings, Image generations, and others. For **API** type, options are Batches and Files.
1. Optional. In **Advanced configuration**, adjust settings such as max request body size, response streaming, and payload logging. The **Return model name header** option is available only for **Model** type.
1. Click **Create**.
{% when 'agent' %}
The following creates a new agent. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Agents**.
1. Click **New agent**.
1. Enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and select a **Type** (for example: `A2A (Agent-to-Agent)`).
1. Optional. Toggle **Log payloads** if you want request and response bodies logged.
1. Enter a **URL** for the upstream connection (for example: `https://booking-agent.internal.example.com`).
1. Optional. Adjust **Max Request Body Size**. The default is `8388608`.
1. Configure the **Route**. Select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules.
1. Optional. Expand **Advanced fields** for further route configuration.
1. Click **Create**.
{% when 'mcp_server' %}
The following creates a new MCP server. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **MCP servers**.
1. Click **New MCP server**.
1. In **General information**, toggle whether this MCP server is enabled, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`), and select a **Type** (for example: `Passthrough listener`).
1. Optional. Toggle **Log payloads** or **Log audits**.
1. In **Configuration**, enter an **Upstream URL** (for example: `https://mcp.internal.example.com`).
1. Optional. Adjust **Max request body size** (default `8388608`), add a **Tag**, or adjust **Timeout** (default `10000`).
1. **Forward client headers** is enabled by default. Disable it if you don't want client headers passed upstream.
1. Optional. Expand **Proxy settings** to configure a proxy for this MCP server.
1. In **Route**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules, or expand **Advanced fields** for further route configuration.
1. In **ACLs**, select an **ACL attribute type** (for example: `Consumer`) to control which consumers can access this server's tools. Optionally expand **Default tool ACL** to configure default allow and deny rules.
1. In **Tools**, click **Add tool** to allow or deny access to specific upstream tools. If no tools are added, requests are proxied to the upstream MCP server without restriction.
1. Click **Create**.
{% when 'vault' %}
The following creates a new AI Vault. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [{{site-ai_gateway}}](https://cloud.konghq.com/ai-gateway/) in the sidebar.
1. Select an {{site.ai_gateway}}.
1. Navigate to **Vaults**.
1. Click **New vault**.
1. Enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and optional **Description** (for example: `{{ include.presenter.data['description'] }}`).
1. Select a **Type** (for example: `{{ include.presenter.data['type'] }}`). The available types are Konnect Config Store, Environment variables, AWS Secrets Manager, Google Secret Manager, Azure Key Vault, CyberArk Conjur, and HashiCorp Vault. The UI surfaces different configuration fields depending on the type you select.
1. If you selected **Environment variables**, enter a **Prefix** (for example: `{{ include.presenter.data['config']['prefix'] }}`) to scope which environment variables this vault resolves against.
1. Click **Create**.
{% else %}
UI instructions are not yet available for this {{site.ai_gateway}} entity type.
{% endcase %}
{% endif %}
