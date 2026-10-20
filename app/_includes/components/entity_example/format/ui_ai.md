{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'model-provider' %}
The following creates a new AI Model Provider. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to **Models** in the sidebar, then select **Providers**.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New provider**.
1. In **Provider**, select a provider (for example: `{{ include.presenter.data['type'] }}`).
1. In **Account details**, enter an **Account name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Authentication**, select **Pass-through** if each caller sends its own provider key, or **Use a credential provider** to have Kong get the credential from Token Vault. For a credential provider, select an existing one, or click **Create credential provider** if none exists.
1. Click **Add provider**.
{% when 'auth-strategy' %}
The following creates a new AI Auth Strategy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Auth Strategies**.
1. Click **New auth strategy**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Type**, select either **Key authentication** or **OpenID Connect**.
1. If you selected **Key authentication**, enter one or more **Key names** (click **Add key name** for more) and select where the key is checked: **Key in header**, **Key in query**, or **Key in body**. Optionally turn on **Hide credentials** or **Run on preflight**. Select whether consumers or Kong Identity own the credentials.
1. If you selected **OpenID Connect**, in the **Common** tab, select **Kong Identity** or **External auth server** as the credential owner.
   - For **Kong Identity**, select an **Authorization server** and a **Client**, and enter the **Client secret**.
   - For **External auth server**, enter a **Client ID**, **Client secret**, and **Issuer**.
   - To change the claim used to match requests to a consumer, turn on **Use identity lookup** and set the **Token claim**.
1. Click **Create**.
{% when 'policy' %}
The following creates a new AI Policy. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways) in the sidebar.
1. Select a gateway.
1. In the **Configuration** tab, select **Policies**.
1. Click **New policy**.
1. In the policy catalog, use **Search policies** or the category list to find the policy you want (for example: `{{ include.presenter.data['type'] }}`), then click **Configure** on its card.
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
1. If you selected **Key**, optionally configure the **First key** section: enter a **Display name** for the key, then enter a **Key** or click **Generate**. Optionally set a **TTL** in seconds (`0` means the key never expires).
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
1. Optional. Under **Model matching**, enter a **Model alias** if you plan to route by request body instead of base path or hostname, and choose a **Match location** (**Request body**, **Header**, or **URL path**).
1. Optional. In **Authentication and access**, configure **Auth strategies** and **Access control**.
1. Optional. In **Advanced configuration**, adjust additional settings.
1. Click **Add model**.

If you selected **Provider API**, the form has **General information**, **Provider**, **Capabilities** (**Batch** and **Files**), **Routing**, **Authentication and access**, and **Advanced configuration** sections, and the final button is **Add provider API**.
{% when 'agent' %}
The following creates a new agent. Suggested values are shown in backticks.

1. In {{site.konnect_short_name}}, navigate to **Agents** in the sidebar.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New agent**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`) and select a **Type** (for example: `A2A (agent-to-agent)`).
1. Optional. Toggle **Log payloads** if you want request and response bodies logged.
1. In **Configuration**, enter a **URL** for the upstream connection (for example: `https://booking-agent.internal.example.com`). Optionally set **Max request body size**.
1. Optional. In **Configuration**, expand **Proxy settings** to set proxy hosts and credentials, or turn on **Authenticate to the upstream service with AWS IAM (SigV4)** under **Outbound authentication**.
1. In **Route**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules.
1. Optional. Expand **Advanced fields** for further route configuration.
1. Optional. In **Authentication and access**, select an **Auth strategy** and configure **Access control**.
1. Click **Create**.
{% when 'mcp_server' %}
The following creates a new AI MCP Server. Suggested values are shown in backticks:

1. In {{site.konnect_short_name}}, navigate to **MCP Servers** in the sidebar.
1. Use the **Gateway** selector at the top of the list to choose a gateway.
1. Click **New MCP server**.
1. In **General information**, enter a **Display name** (for example: `{{ include.presenter.data['display_name'] }}`).
1. In **Configuration**, choose what the server connects to: **An existing MCP server** (a Passthrough listener), **A RESTful API** (a Conversion listener that turns API paths into MCP tools), or **Other MCP servers on this gateway**. Then enter an **Upstream URL** (for example: `https://mcp.internal.example.com`). Under **Callable** the clients call this server directly; **Source only** makes it a source for other listeners.
1. Optional. In **Logging**, toggle **Log payloads** or **Log audits**.
1. **Forward client headers** is enabled by default. Disable it if you don't want client headers passed upstream.
1. Optional. In **Configuration**, expand **Advanced fields** for additional settings.
1. In **Route**, select **Base path** and enter a path (for example: `/`). Click **Add route rule** to add additional routing rules, or expand **Advanced fields** for further route configuration.
1. In **Tools**, click **Add tool** to allow or deny access to specific upstream tools. If no tools are added, requests are proxied to the upstream MCP server without restriction.
1. In **Authentication and access**, select an **Auth strategy** under **Inbound authentication**. Optional. Under **Outbound authentication**, click **Edit** to choose how Kong authenticates to the upstream (**Pass-through** by default). Under **ACLs**, turn on **Restrict access with an ACL** to set **Server ACLs**. For **Tool ACLs**, choose what to evaluate in **Evaluate tool ACLs against** (for example: `Consumer group`) and click **Add rule**.
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
