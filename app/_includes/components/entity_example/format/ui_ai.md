{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'model-provider' %}
The following creates a new AI Model Provider. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click **Models**.
1. Under **Models**, click **Providers**.
1. From the **Gateway** dropdown menu, select your {{site.ai_gateway}}.
1. Click **New provider**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. From the **Provider** dropdown menu, select your provider (for example: `{{ include.presenter.data['type'] }}`).
1. In **Authentication**, select **Provided by AI gateway** or **Provided by client or agent**.
1. If you selected **Provided by AI gateway**, enter the credentials that the provider requires.
1. Click **Create**.
{% when 'auth-strategy' %}
The following creates a new AI Auth Strategy. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways).
1. Select your {{site.ai_gateway}}.
1. Click the **Auth strategies** tab.
1. Click **New auth strategy**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. In **Type**, select **Key authentication** or **OpenID Connect**.
1. In **Configuration**, configure the fields for the type you selected.
1. Click **Create**.
{% when 'policy' %}
The following creates a new AI Policy. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways).
1. Select your {{site.ai_gateway}}.
1. Click the **Policies** tab.
1. Click **New policy**.
1. In the policy catalog, find the policy (for example: `{{ include.presenter.data['type'] }}`) and click **Configure**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
{% if include.presenter.data['global'] %}
1. In **Scope**, select **Global**.
1. In **Policy configuration**, configure the policy fields.
1. Click **Create**.
{% else %}
1. In **Scope**, select **Scoped**.
1. In **Policy configuration**, configure the policy fields.
1. Click **Create and next**.
1. Select the models, MCP servers, or agents that the policy applies to.
{% endif %}
{% when 'consumer' %}
The following creates a new AI Consumer. Consumers are managed in the API Management lens of {{site.konnect_short_name}}. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} lens switcher on the far left, click **API**.
1. In the {{site.konnect_short_name}} sidebar, click **{{site.ai_gateway}}**.
1. Select your {{site.ai_gateway}}.
1. Click the **Consumers** tab.
1. Click **New consumer**.
1. In **Consumer type**, select **API key** or **OAuth**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. If you selected **OAuth**, click **Create**.
1. If you selected **API key**, click **Next**, then click **Generate key** and **Create key**, or click **Skip** to add a key later.
{% when 'consumer_group' %}
The following creates a new AI consumer group. Consumer groups are managed in the API Management lens of {{site.konnect_short_name}}. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} lens switcher on the far left, click **API**.
1. In the {{site.konnect_short_name}} sidebar, click **{{site.ai_gateway}}**.
1. Select your {{site.ai_gateway}}.
1. Click the **Consumers** tab.
1. Click the **Groups** tab.
1. Click **New consumer group**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. Optional: Select the consumers to add to the group.
1. Click **Create**.
{% when 'model' %}
The following creates a new model. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click **Models**.
1. Under **Models**, click **Models**.
1. From the **Gateway** dropdown menu, select your {{site.ai_gateway}}.
{% if include.presenter.data['type'] == 'api' %}
1. From the **New** dropdown menu, select "Provider API".
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. In **Target provider**, select your provider (for example: `{{ include.presenter.data['targets'][0]['provider'] }}`).
1. In **Capabilities**, select the provider APIs to expose.
{% else %}
1. From the **New** dropdown menu, select "Model".
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. In **Target models**, select a **Provider** (for example: `{{ include.presenter.data['targets'][0]['provider'] }}`).
1. In the **Target model** field, enter `{{ include.presenter.data['targets'][0]['name'] }}`.
1. In **Capabilities**, select the capabilities and API formats that the model supports.
{% endif %}
1. In **Routing**, in the **Base path** field, enter `{{ include.presenter.data['config']['route']['paths'][0] | default: '/' }}`.
1. Optional: In **Authentication and access**, select an auth strategy and enable **Restrict access with an ACL**.
1. Click **Create**.
{% when 'agent' %}
The following creates a new agent. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click **Agents**.
1. From the **Gateway** dropdown menu, select your {{site.ai_gateway}}.
1. Click **New agent**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. From the **Type** dropdown menu, select "A2A (Agent-to-Agent)".
1. In the **URL** field, enter `{{ include.presenter.data['config']['url'] }}`.
1. In **Route**, in the **Base path** field, enter `{{ include.presenter.data['config']['route']['paths'][0] | default: '/' }}`.
1. Optional: In **Access**, select an **Auth strategy** and enable **Restrict access with an ACL**.
1. Click **Create**.
{% when 'mcp_server' %}
{% case include.presenter.data['type'] %}
{% when 'passthrough-listener' %}{% assign connection = 'Passthrough' %}
{% when 'listener' %}{% assign connection = 'Interface' %}
{% else %}{% assign connection = 'From API' %}
{% endcase %}
The following creates a new AI MCP Server. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click **MCP Servers**.
1. From the **Gateway** dropdown menu, select your {{site.ai_gateway}}.
1. From the **New** dropdown menu, select "MCP server".
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. In **Connection**, select **{{ connection }}**.
{% if connection == 'Interface' %}
1. In **Configuration**, from the **Sources** dropdown menu, select the sources to expose.
{% else %}
1. In the **Upstream URL** field, enter `{{ include.presenter.data['config']['url'] | default: 'https://mcp.example.com' }}`.
{% endif %}
1. In **Routing config**, in the **Base path** field, enter `{{ include.presenter.data['config']['route']['paths'][0] | default: '/' }}`.
1. Optional: In **Tools**, click **Add tool** to define or restrict the tools.
1. Optional: In **Authentication**, select an inbound auth strategy and configure outbound authentication.
1. Optional: In **Access control**, enable **Restrict access with an ACL** and add default tool ACLs.
1. Click **Create**.
{% when 'vault' %}
The following creates a new AI Vault. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click [**Gateways**](https://cloud.konghq.com/ai-manager/v2/gateways).
1. Select your {{site.ai_gateway}}.
1. Click the **Vaults** tab.
1. Click **New vault**.
1. In **Vault configuration**, select the vault type (for example: `{{ include.presenter.data['type'] }}`) and enter the fields for that type.
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
1. Optional: In the **Description** field, enter a description.
1. Click **Save**.
{% else %}
UI instructions are not yet available for this {{site.ai_gateway}} entity type.
{% endcase %}
{% endif %}
