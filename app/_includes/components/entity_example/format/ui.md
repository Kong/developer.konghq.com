{% if page.layout == 'gateway_entity' %}
{% case include.presenter.entity_type %}
{% when 'consumer' %}
The following creates a new Consumer called **{{ include.presenter.data['username'] }}**:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Consumers**.
1. Click **New Consumer**.
1. Enter the **Username** `{{ include.presenter.data['username'] }}` and **Custom ID** `{{ include.presenter.data['custom_id'] }}`.
1. Click **Save**.
{% when 'consumer_group' %}
The following creates a new Consumer Group called **{{ include.presenter.data['name'] }}**:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Consumers**.
1. Click the **Consumer Groups** tab.
1. Click **New Consumer Group**.
1. Enter the **Name** `{{ include.presenter.data['name'] }}`.
1. Click **Save**.
{% when 'route' %}
The following creates a new Route called **{{ include.presenter.data['name'] }}** with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Routes**.
1. Click **New Route**.
1. Enter a unique name and select a Service to assign the Route to. In this example, the Route is named `{{ include.presenter.data['name'] }}`.
1. Set a path or define routing rules. For example, the path can be `{{ include.presenter.data['paths']}}`.
1. Click **Save**.
{% when 'service' %}
The following creates a new Gateway Service called **{{ include.presenter.data['name'] }}** with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Gateway Services**.
1. Click **New Gateway Service**.
1. Enter a unique name for the Service. In this example, it's `{{ include.presenter.data['name'] }}`.
1. Define the endpoint for this Service by specifying the full URL or by its separate elements. In this example, the full upstream URL is `{{ include.presenter.data['url'] }}`.
1. Click **Save**.
{% when 'plugin' %}

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Select **Plugins**.
1. Click **New Plugin** and choose a plugin.
1. Choose a scope for the plugin:
    * **Global**, which applies the plugin to all Gateway Services, Routes, Consumers, and Consumer Groups in the Workspace (Kong Manager) or control plane ({{site.konnect_short_name}}).
    * **Scoped**, which lets you choose a specific Gateway Service, Route, Consumer, or Consumer Group to apply the plugin to.
    The types of entities you have available here depend on the plugin you picked.

1. Configure your plugin. The configuration options will depend on which plugin you picked.
1. Click **Save**.
{% when 'target' %}
The following creates a new Upstream and a Target with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Upstreams**.
1. Click **New Upstream**.
1. Enter a unique name for the Upstream. For example: `example_upstream`.
1. Click **Save**.
1. From your Upstream, click the **Targets** tab.
1. Click **New Target**.
1. Enter an IP address/hostname and port in the **Target Address** field. For example: `{{ include.presenter.data['target'] }}`
1. Update the weight. For example: `{{ include.presenter.data['weight'] }}`.
1. Click **Save**.
{% when 'upstream' %}
The following creates a new Upstream with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Upstreams**.
1. Click **New Upstream**.
1. Enter a unique name for the Upstream. For example: `{{ include.presenter.data['name'] }}`.
1. Click **Save**.
{% when 'vault' %}
The following creates a new Vault with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Vaults**.
1. Click **New Vault**.
1. Select a type of Vault to configure. For example: `{{ include.presenter.data['name'] }}`
1. Enter a prefix for the Vault. For example: `{{ include.presenter.data['prefix'] }}`
1. Enter a description for the Vault. For example: `{{ include.presenter.data['description'] }}`
1. Click **Save**.
{% when 'sni' %}
The following creates a new SNI with basic configuration:
1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Certificates**.
1. Select the SNIs tab, and click **New SNI**.
1. In the **Name** field, enter a name for the SNI: `{{ include.presenter.data['name'] }}`
1. In the **SSL Certificate ID** field, select or enter the ID for an existing Certificate: `{{ include.presenter.data['certificate']['id'] }}`
1. Click **Save**.

{% when 'workspace' %}
The following creates a new Workspace:

1. From the Kong Manager Dashboard, click **New Workspace**.
2. Add a name, then click **Create New Workspace**.

This will create a new Workspace, and from here you can start managing entities from Kong Manager.

{% when 'certificate' %}
The following creates a new Certificate with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Certificates**.
1. Click **New Certificate**.
1. In the **Cert** field, enter the PEM-encoded public certificate:
    ```
    {{ include.presenter.data['cert'] }}
    ```
1. In the **Key** field, enter the PEM-encoded private key:
    ```
    {{ include.presenter.data['key'] }}
    ```
1. Click **Save**.
{% when 'ca_certificate' %}
The following creates a new CA Certificate with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Certificates**.
1. Click the **CA Certificates** tab.
1. Click **New CA Certificate**.
1. In the **Cert** field, enter the PEM-encoded public certificate of the CA:
    ```
    {{ include.presenter.data['cert'] }}
    ```
1. Click **Save**.
{% when 'rbac' %}
The following instructions create an RBAC user in Kong Manager. `kong.conf` must be configured to `ENFORCE_RBAC=on`.

1. In Kong Manager, go to **Teams**. 
1. Click the **RBAC Users** tab.
1. Select the appropriate [Workspace](/gateway/entities/workspace/) then **Add new user**.
1. Create a **Name** and **User Token**.
1. Click **Create**. 
{% when 'key' %}
The following creates a new JSON Web Key with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Keys**.
1. Click **New Key**.
1. In the **Key ID** field, enter the key ID. It should match the `kid` field in the key:
    ```
    {{ include.presenter.data['kid'] }}
    ```
1. Enter a name for the Key:
    ```
    {{ include.presenter.data['name'] }}
    ```
1. In the **JWK** field, enter the JSON Web Key:
    ```
    {{ include.presenter.data['jwk'] }}
    ```
1. Click **Save**.
{% when 'key-set' %}
The following creates a new JSON Web Key Set with basic configuration:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Keys**.
1. Click the **Key Sets** tab.
1. Click **New Key Set**.
1. Enter a name for the Key Set:
    ```
    {{ include.presenter.data['name'] }}
    ```
1. Click **Save**.
{% when 'group' %}
The following instructions create a Group in Kong Manager. Groups are a function of RBAC, and require RBAC to be [enabled](/gateway/entities/rbac/#enable-rbac).

1. In Kong Manager, go to **Teams**.
1. Click the **Groups** tab. 
1. Click **New Group**.
1. Enter a name for your Group.
1. Select **Add/Edit Roles** to assign Roles to this Group.
1. Click **Create**.

{% when 'admin' %}
If you have configured [RBAC](/gateway/entities/rbac/#enable-rbac) and configured Kong Manager to send email, you can create new Admins from within Kong Manager: 

1. In Kong Manager, navigate to **Teams**.
1. Click **Invite Admin**. 
1. Enter the appropriate information for your Admin. 
1. Select the desired [Roles](/gateway/entities/rbac/#default-kong-gateway-roles).
1. Click **Invite Admin**.

If you have not configured Kong Manager to send email, you can generate a registration link by selecting the newly invited Admin, and clicking **Generate Registration Link**.

{% when 'partial' %}
The following creates a new Partial called **{{ include.presenter.data['name'] }}**:

1. Navigate to your Gateway instance:
  * In Konnect, open **API Gateway** from the sidebar, then choose a control plane.
  * In Kong Manager, select your Workspace.
1. Navigate to **Redis Configurations**.
1. Click **New configuration**.
1. Select the **Redis type** `Host/Port (Enterprise)`.
1. Enter the **Name** `{{ include.presenter.data['name'] }}`.
1. Enter the **Host** `{{ include.presenter.data['config']['host'] }}` and **Port** `{{ include.presenter.data['config']['port'] }}`.
1. Click **Save**.

{% when 'backend_cluster' %}
The following creates a new backend cluster called **{{ include.presenter.data['name'] }}** with basic configuration:

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click an {{site.event_gateway_short}}.
1. Navigate to **Backend Clusters** in the sidebar.
1. Click **New backend cluster**.
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
1. In the **Bootstrap servers** field, enter `{{ include.presenter.data['bootstrap_servers'] | first }}`.
1. From the **Authentication** dropdown menu, select `{{ include.presenter.data['authentication']['type'] }}`
1. Select the **Allow anonymous authentication from virtual clusters** checkbox.
1. Click **Save**.

{% when 'virtual_cluster' %}
The following creates a new virtual cluster called **{{ include.presenter.data['name'] }}** with basic configuration:

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
2. Click an {{site.event_gateway_short}}.
3. Navigate to **Virtual Clusters** in the sidebar.
4. Click **New Virtual Cluster**.
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
5. Configure your virtual cluster.
6. Click **Save and add policy**.

At this point, you can choose to add a policy, or exit out and add a policy later.

{% when 'listener' %}
The following creates a new listener called **{{ include.presenter.data['name'] }}** with basic configuration:

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click an {{site.event_gateway_short}}.
1. Navigate to **Listeners** in the sidebar.
1. Click **New listener**.
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
2. In the **Addresses** field, enter `{{ include.presenter.data['addresses'] | first }}`.
3. In the **Ports** field, enter `{{ include.presenter.data['ports'] | first }}`.
4. Click **Save and add policy next**.
5. Click **Maybe later** to create a listener without a policy.

{% when 'schema_registry' %}

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click an {{site.event_gateway_short}}.
3. Navigate to **Resources** in the sidebar.
1. Click **New Schema Registry**.
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
1. Configure your schema registry.
1. Click **Create**.

{% when 'static_key' %}

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click an {{site.event_gateway_short}}.
1. Navigate to **Resources** in the sidebar.
1. Click **Static keys**
1. Click **New Static key**.
1. In the **Key name** field, enter `{{ include.presenter.data['name'] }}`.
1. In the **Value** field, enter `{{ include.presenter.data['value'] }}`.
1. Click **Save**.


{% when 'event_gateway_policy' %}

{% case include.presenter.policy_type %}
{% when 'modify-headers' %}
The following creates a new Modify Headers policy called **{{ include.presenter.data['name'] }}** to a virtual cluster with basic configuration:

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click an {{site.event_gateway_short}}.
1. Navigate to **Virtual Clusters** in the sidebar.
1. Click on a virtual cluster.
1. Click **Policies**.
1. Click **New policy**.
1. Click **Consume**.
1. Choose **Modify Headers**.
1. Click **Configure**
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
1. In the **Actions** sections:
  {% assign action = include.presenter.data['config']['actions'] | first %}
   1. In the **Header Key** field, enter `{{ action['key'] }}`.
   2. In the **Header Value** field, enter `{{ action['value'] }}`.
1.  Click **Save**.

{% when 'forward-to-virtual-cluster' %}
The following creates a new Forward to Virtual Cluster policy called **{{ include.presenter.data['name'] }}** to a listener with basic configuration:

1. In {{site.konnect_short_name}}, navigate to [{{site.event_gateway_short}}](https://cloud.konghq.com/event-gateway/) in the sidebar.
1. Click an {{site.event_gateway_short}}.
1. Navigate to **Listeners** in the sidebar.
1. Click on a listener.
1. Click **Policies**.
1. Click **New policy**.
1. Choose **Forward to virtual cluster**.
1. Click **Configure**
1. In the **Name** field, enter `{{ include.presenter.data['name'] }}`.
1. Choose **Port mapping**.
1. In the **Target virtual cluster** field, enter `{{ include.presenter.data['config']['destination']['name'] }}`.
1. In the **Advertised host** field, enter `{{ include.presenter.data['config']['advertised_host'] }}`.
1. In the **Minimal broker Id** field, enter `{{ include.presenter.data['config']['min_broker_id'] }}`.
1. Click **Save**.

{% else %}
Unsupported type {{include.presenter.policy_type}}.
{% endcase %}

{% else %}
{% endcase %}
{% endif %}


