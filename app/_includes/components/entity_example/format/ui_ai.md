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
The following creates a new AI Consumer. Consumers are managed in the API view of {{site.konnect_short_name}}. Suggested values are shown in backticks:

1. On the far left of {{site.konnect_short_name}}, click **API** to switch to the API view.
1. In the {{site.konnect_short_name}} sidebar, click **{{site.ai_gateway}}**.
1. Select your {{site.ai_gateway}}.
1. Click the **Consumers** tab.
1. Click **New consumer**.
1. In **Consumer type**, select **API key** or **OAuth**.
1. Click **Next**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. In the **Custom ID** field, enter a unique ID.
1. If you selected **OAuth**, click **Create**.
1. If you selected **API key**, click **Next**.
1. In the **Display name** field, enter a name for the key.
1. Choose one of the following methods to create your API key:
    * Manually enter a key, save it, then click **Create key**
    * Click **Generate key**, save the generated key, then click **Create key**.
    * Click **Create key**. The generated key appears in a dialog. Save the key and click **Done**.
    * Click **Skip** to add a key later.
{% when 'consumer_group' %}
The following creates a new AI Consumer Group. Consumer Groups are managed in the API view of {{site.konnect_short_name}}. Suggested values are shown in backticks:

1. On the far left of {{site.konnect_short_name}}, click **API** to switch to the API view.
1. In the {{site.konnect_short_name}} sidebar, click **{{site.ai_gateway}}**.
1. Select your {{site.ai_gateway}}.
1. Click the **Consumers** tab.
1. Click the **Groups** tab.
1. Click **New consumer group**.
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. Optional: Select the Consumers to add to the group.
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
{% assign mcp_type = include.presenter.data['type'] %}
{% case mcp_type %}
{% when 'passthrough-listener', 'upstream-server' %}{% assign configuration = 'An existing MCP server' %}
{% when 'listener' %}{% assign configuration = 'Other MCP servers on this gateway' %}
{% else %}{% assign configuration = 'A RESTful API' %}
{% endcase %}
{% if mcp_type == 'upstream-server' or mcp_type == 'conversion-only' %}{% assign exposure = 'Source only' %}{% else %}{% assign exposure = 'Callable' %}{% endif %}
The following creates a new AI MCP Server. Suggested values are shown in backticks:

1. In the {{site.konnect_short_name}} sidebar, click **MCP Servers**.
1. From the **Gateway** dropdown menu, select your {{site.ai_gateway}}.
1. From the **New** dropdown menu, select "MCP server".
1. In the **Display name** field, enter `{{ include.presenter.data['display_name'] }}`.
1. In **Configuration**, select **{{ configuration }}**.
{% if mcp_type == 'listener' %}
1. In **Sources**, select the checkbox for each source-only MCP server whose tools this server exposes.
{% else %}
1. Click the **{{ exposure }}** tab.
{% if mcp_type == 'conversion-only' %}
1. In the **Upstream URL** field, enter `{{ include.presenter.data['config']['url'] | default: 'https://api.example.com' }}`.
{% elsif include.presenter.data['config']['targets'] %}
1. In **Upstream**, click the **Multiple targets** tab.
{% for target in include.presenter.data['config']['targets'] %}
{% if forloop.index > 2 %}
1. Click **Add target**.
{% endif %}
1. In target row {{ forloop.index }}, in the **Address** field, enter `{{ target['address'] }}`.
{% if target['weight'] and target['weight'] != 100 %}
1. In target row {{ forloop.index }}, in the **Weight** field, enter `{{ target['weight'] }}`.
{% endif %}
{% if target['failover'] %}
1. In target row {{ forloop.index }}, enable **Failover only**.
{% endif %}
{% endfor %}
{% assign algorithm = include.presenter.data['config']['balancer']['algorithm'] %}
{% if algorithm %}
1. In **Load balancing**, from the **Algorithm** dropdown menu, select "{{ algorithm | replace: '-', ' ' | capitalize }}".
{% endif %}
{% else %}
1. In **Upstream**, click the **Single URL** tab.
{% if configuration == 'An existing MCP server' %}
1. In the **Upstream URL** field, enter `{{ include.presenter.data['config']['url'] | default: 'https://mcp.example.com' }}`.
1. Optional: To connect a third-party MCP server such as GitHub or Slack, click **Browse library** instead.
1. Optional: In the **Choose an MCP server** dialog, click the MCP server. {{site.konnect_short_name}} fills in the display name and the upstream URL, which you can change afterwards.
{% else %}
1. In the **Upstream URL** field, enter `{{ include.presenter.data['config']['url'] | default: 'https://api.example.com' }}`.
{% endif %}
{% endif %}
{% if mcp_type == 'upstream-server' %}
1. In the **Tools cache TTL (seconds)** field, enter `{{ include.presenter.data['config']['tools_cache_ttl_seconds'] | default: 0 }}`.
{% if include.presenter.data['config']['server']['preserve_upstream_tool_names'] %}
1. Select the **Preserve upstream tool names** checkbox.
{% endif %}
{% endif %}
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
