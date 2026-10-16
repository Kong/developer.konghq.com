{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'model-provider' %}
The following creates a new AI Model Provider. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to **Models** in the sidebar, then select **Providers**.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New provider**.
1. In **Provider**, select a provider (for example: `{{ include.presenter.data['type'] }}`).
1. In **Account details**, enter an **Account name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Authentication**, enter a **Credential name** and the credential for the selected provider, such as an **API key**.
1. Click **Add provider**.
{% when 'auth-strategy' %}
The following creates a new AI Auth Strategy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Auth Strategies**.
1. Click **New auth strategy**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Type**, select either **Key authentication** or **OpenID Connect**.
1. If you selected **Key authentication**, enter the **Key names** and select where the key is checked: **Key in header**, **Key in query**, or **Key in body**. Optionally, select a **Credential owner**.
1. If you selected **OpenID Connect**, select a **Credential owner**. For an external auth server, enter an **Issuer**, **Client ID**, and **Client secret**. To change the claim used to match requests to a consumer, select **Show additional settings** and set the **Token claim**.
1. Click **Create**.
{% when 'policy' %}
The following creates a new AI Policy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Policies**.
1. Click **New policy**.
1. In the policy catalog, find the policy you want (for example: `{{ include.presenter.data['type'] }}`) and click **Configure**.
1. In **General information**, toggle **Enabled** and enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Scope**, set **Applies to** to **Scoped** and click **Add entities**, or to **Global**.
1. Configure the policy fields.
1. Click **Create policy**.
{% when 'consumer' %}
The following creates a new AI Consumer. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Consumers**.
1. Click **New consumer**.
1. In **Consumer type**, select **Key** or **OAuth** (for example: `{{ include.presenter.data['type'] }}`).
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Custom ID** (for example: `{{ include.presenter.data['custom_id'] }}`). The **Custom ID** is required for **OAuth** consumers.
1. Optional. Select one or more **Consumer groups**.
1. If you selected **Key**, optionally configure the **First key** section: enter a **Display name** for the key, enter a **Key** or click **Generate**, and set a **TTL**.
1. If you selected **OAuth**, authentication for this consumer type is handled by an OpenID Connect policy matched to the consumer's **Custom ID**, not by a key.
1. Click **Create**.
{% when 'consumer_group' %}
The following creates a new AI consumer group. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Consumer Groups**.
1. Click **New consumer group**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. Click **Create**.

To add consumers to the group, select the group in the **Consumer groups** field when you create or edit a consumer.
{% when 'model' %}
The following creates a new model. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to **Models** in the sidebar, then select **Models**.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New model**, then select **Model** for generative and embeddings requests, or **Provider API** for files and batch operations.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Target models**, select a **Provider**. If you selected **Model**, also select a **Target model**. Click **Add target model** to route requests across multiple providers.
1. In **Capabilities**, select which AI capabilities this model supports. For **Model**, options include **Generate**, **Embeddings**, and **Image generation**. For **Provider API**, options include **Batch** and **Files**.
1. In **Routing**, under **Route matching**, select **Base path** and enter a path to determine how the {{site.ai_gateway}} is accessed. Don't include capability-specific paths such as `/chat/completions`. Click **Add route rule** to add more rules.
1. Optional. Under **Model matching**, enter a **Model alias** if you plan to route by request body instead of base path or hostname.
1. Optional. In **Authentication and access**, configure **Auth strategies** and **Access control**.
1. Optional. In **Advanced configuration**, adjust settings such as **Max request body size**, **Response streaming**, and **Log payloads**.
1. Click **Add model**.
{% when 'agent' %}
The following creates a new agent. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to **Agents** in the sidebar.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New agent**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and select a **Type** (for example: `A2A (agent-to-agent)`).
1. Optional. Toggle **Log payloads** if you want request and response bodies logged.
1. In **Configuration**, enter a **URL** for the upstream connection (for example: `https://booking-agent.internal.example.com`).
1. Optional. Adjust **Max request body size**. The default is `8388608`.
1. In **Route**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules.
1. Optional. Expand **Advanced fields** for further route configuration.
1. Click **Create**.
{% when 'mcp_server' %}
The following creates a new AI MCP Server. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to **MCP Servers** in the sidebar.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New MCP server**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Configuration**, select a **Type** (for example: `Passthrough listener`) and enter an **Upstream URL** (for example: `https://mcp.internal.example.com`).
1. Optional. In **Logging**, toggle **Log payloads** or **Log audits**.
1. **Forward client headers** is enabled by default. Disable it if you don't want client headers passed upstream.
1. Optional. Expand **Advanced fields** to adjust **Max request body size** (default `8388608`) or **Timeout** (default `10000`). For the **Passthrough listener** type, this section also includes **Proxy** settings.
1. In **Route**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules, or expand **Advanced fields** for further route configuration.
1. In **Tools**, click **Add tool** to allow or deny access to specific upstream tools. If no tools are added, requests are proxied to the upstream MCP server without restriction.
1. In **Authentication and access**, select an **Auth strategy** under **Inbound authentication**. Under **Access control**, select what to evaluate tool ACLs against in **Evaluate tool ACLs against** (for example: `Consumer group`), then add **Server ACLs** or **Tool ACLs** rules.
1. Click **Create MCP server**.
{% when 'vault' %}
The following creates a new AI Vault. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Vaults**.
1. Click **New vault**.
1. In **Vault configuration**, select a **Type** (for example: `{{ include.presenter.data['type'] }}`). The available types are Konnect, Environment variables, AWS Secrets Manager, Google Secret Manager, HashiCorp Vault, Azure Vault, and CyberArk Secrets Manager (Conjur). The UI surfaces different configuration fields depending on the type you select.
1. If you selected **Environment variables**, enter an **Environment variable prefix** (for example: `{{ include.presenter.data['config']['prefix'] }}`) to scope which environment variables this vault resolves against.
1. In **General information**, enter a **Name** (for example: `{{ include.presenter.data['display_name'] }}`) and optional **Description** (for example: `{{ include.presenter.data['description'] }}`).
1. Click **Create**.
{% else %}
UI instructions are not yet available for this {{site.ai_gateway}} entity type.
{% endcase %}
{% endif %}
