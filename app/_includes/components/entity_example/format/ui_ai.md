{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'model-provider' %}
The following creates a new AI Model Provider. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to **Models** in the sidebar, then select **Providers**.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New provider**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Provider and authentication**, select a **Provider** (for example: `{{ include.presenter.data['type'] }}`).
1. Under **Authentication**, select **Provided by client or agent** if each caller sends its own provider key. Otherwise, select **Provided by AI gateway**, then enter the **Header name** and **Header value** (labeled **API key** for some providers), or the **Parameter name**, **Parameter value**, and **Parameter location**, that the provider expects. Click **Look up key in vault** next to a field to reference a vault secret instead. Some providers ask for more: **Azure** asks for a **Service** and an **Azure instance**, and **Azure** and **Amazon Bedrock** have an **Authentication method** choice.
1. Click **Create**.
{% when 'auth-strategy' %}
The following creates a new AI Auth Strategy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. Select the **Auth strategies** tab.
1. Click **New auth strategy**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Type**, select either **Key authentication** or **OpenID Connect**.
1. If you selected **Key authentication**, enter one or more **Key names** (click **Add key names** for more) and select where the key is checked: **Key in header**, **Key in query**, or **Key in body**. Optionally turn on **Hide credentials** or **Run on preflight**. Under **Who should manage authentication and credentials?**, select **Consumers** or **Kong Identity**.
1. If you selected **OpenID Connect**, in the **Common** tab, under **Who should manage authentication and credentials?**, select **Kong Identity** or **External auth server**.
   - For **Kong Identity**, select an **Authorization Server** and a **Client** (or click **Add client**), and enter the **Client secret**.
   - For **External auth server**, enter a **Client ID**, **Client secret**, and **Issuer**.
   - To change the claim used to match requests to a consumer, turn on **Use identity lookup** and set the **Token claim**.
1. Click **Create**.
{% when 'policy' %}
The following creates a new AI Policy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. Select the **Policies** tab.
1. Click **New policy**.
1. In the policy catalog, use **Search policies** or the category list to find the policy you want (for example: `{{ include.presenter.data['type'] }}`), then click **Configure** on its card.
1. In **General information**, turn on **This policy is enabled** and enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Scope**, select **Scoped** or **Global**.
1. In **Policy configuration**, configure the policy fields.
1. Click **Create and next**.
1. If you selected **Scoped**, in the **Add entities** step, select the entities the policy applies to.
{% when 'consumer' %}
The AI lens has no **Consumers** page, because Consumers are being replaced by Users and Groups. To manage existing consumers, use the API lens:

1. In {{site.konnect_short_name}}, switch to the API lens and navigate to **AI Gateway**.
1. Select a gateway, then open the **Consumers** tab.
1. Click **New consumer**.
1. In **Consumer type**, select **API key** or **OAuth** (for example: `{{ include.presenter.data['type'] }}`), then click **Next**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and **Custom ID** (for example: `{{ include.presenter.data['custom_id'] }}`). If you selected **OAuth**, click **Create**. The consumer is created and the wizard ends.
1. If you selected **API key**, click **Next**. The consumer is created at this step. In **Add a key**, optionally enter a **Display name**, then enter a **Key** or click **Generate key**, and set a **TTL** (`0` means the key never expires). Click **Create key**, or click **Skip** to add keys later.
{% when 'consumer_group' %}
The AI lens has no consumer groups page, because Consumer Groups are being replaced by Groups. To manage existing consumer groups, use the API lens:

1. In {{site.konnect_short_name}}, switch to the API lens and navigate to **AI Gateway**.
1. Select a gateway, open the **Consumers** tab, then select **Groups**.
1. Click **New consumer group**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. Optional. In **Consumers**, click **Select consumers** to add consumers to the group.
1. Click **Create**.
{% when 'model' %}
The following creates a new model. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to **Models** in the sidebar, then select **Models**.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New**, then select **Model** for generative and embeddings requests, or **Provider API** for files and batch operations.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Target models**, select a **Provider**. If you selected **Model**, also select a **Target model**. Click **Add target model** to route requests across multiple providers.
1. In **Capabilities**, review the API formats the gateway translates for the target providers, such as **OpenAI** and **Anthropic**. The formats appear after you select a provider for a target model. Optional. To restrict the formats and endpoints, or to turn on **Passthrough mode**, click **Advanced fields**.
1. In **Routing**, under **Route matching**, select **Base path** and enter a path to determine how the {{site.ai_gateway}} is accessed. Don't include capability-specific paths such as `/chat/completions`. Click **Add route rule** to add more rules.
1. Optional. Under **Model matching**, enter a **Model alias** if you plan to route by request body instead of base path or hostname, and choose a **Custom match location**.
1. Optional. In **Authentication and access**, select an **OAuth 2.0** or **API key** auth strategy under **Auth strategies**. Under **Access control**, turn on **Restrict access with an ACL** to limit who can use the model, then select a **Mode** (**Allow list**, **Deny list**, **Allow expression**, or **Deny expression**) and the **Values**.
1. Optional. In **Advanced configuration**, adjust additional settings.
1. Click **Create**.

If you selected **Provider API**, the form has **General information**, **Target provider**, **Capabilities**, **Routing**, **Authentication and access**, and **Advanced configuration** sections. It has no **Model matching** block. Under **Capabilities** > **Advanced fields**, the **OpenAI** format lists the **Batches** and **Files** endpoints.
{% when 'agent' %}
The following creates a new agent. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to **Agents** in the sidebar.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New agent**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and select a **Type** (for example: `A2A (agent-to-agent)`).
1. Optional. Toggle **Log payloads** if you want request and response bodies logged.
1. In **Configuration**, enter a **URL** for the upstream connection (for example: `https://booking-agent.internal.example.com`). Optionally set **Max request body size**.
1. Optional. In **Configuration**, click **Advanced fields** to set **Upstream authentication** (**Authenticate to the upstream service with AWS IAM (SigV4)**), **Upstream TLS**, or **Proxy settings**.
1. In **Route**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules.
1. Optional. In **Route**, click **Advanced fields** for **Preserve host**, **Request buffering**, and **Response buffering**.
1. Optional. In **Access**, select an **Auth strategy**. Under **Access control**, turn on **Restrict access with an ACL** to limit who can use the agent.
1. Click **Create**.
{% when 'mcp_server' %}
The following creates a new AI MCP Server. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to **MCP Servers** in the sidebar.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New**, then select **MCP server**. To create a source of tools for other servers, select **Tool source** instead.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and, under **Connection**, select **Passthrough** (proxy to an existing upstream MCP server), **Interface** (expose one endpoint built from toolsets on this gateway), or **From API** (expose a RESTful API's operations as MCP tools).
1. In **Configuration**, enter an **Upstream URL** (for example: `https://mcp.internal.example.com`). For **Interface**, click **Select toolsets** under **Sources** instead.
1. Optional. In **Configuration**, click **Advanced** to set **Forward client headers**, **Timeout**, **Logging** (**Log payloads** and **Log audits**), **Max request body size**, **Proxy**, and **Upstream TLS**.
1. In **Routing config**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules, or click **Advanced fields** for further route configuration.
1. In **Tools**, click **Add tool**. For **Passthrough**, this allows or denies access to specific upstream tools, and with no tools the requests are proxied without restriction. For **From API**, add at least one tool to define the API operations the server exposes. For **Interface**, the tools come from the selected toolsets.
1. In **Authentication**, select an **Auth strategy** under **Inbound authentication**, or click **New strategy** to create one. Optional. For **Passthrough** and **From API**, under **Outbound authentication**, click **Edit**, select **Pass-through** or **AWS SigV4**, and click **Apply**.
1. Optional. In **Access control**, turn on **Restrict access with an ACL** to set **Server ACLs**. Under **Default tool ACLs**, set **Rule type** to **By name** or **By expression**, then click **Add allow** or **Add deny**.
1. Click **Create**.
{% when 'vault' %}
The following creates a new AI Vault. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. Select the **Vaults** tab.
1. Click **New vault**.
1. In **Vault configuration**, select a **Type** (for example: `{{ include.presenter.data['type'] }}`). The available types are Konnect, Environment variables, AWS Secrets Manager, Google Secret Manager, HashiCorp Vault, Azure Vault, and CyberArk Secrets Manager (Conjur). The UI surfaces different configuration fields depending on the type you select.
1. If you selected **Environment variables**, enter an **Environment variable prefix** (for example: `{{ include.presenter.data['config']['prefix'] }}`) to scope which environment variables this vault resolves against.
1. In **General information**, enter a **Name** (for example: `{{ include.presenter.data['display_name'] }}`) and optional **Description** (for example: `{{ include.presenter.data['description'] }}`).
1. Click **Save**.
{% else %}
UI instructions are not yet available for this {{site.ai_gateway}} entity type.
{% endcase %}
{% endif %}
