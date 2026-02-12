# Front matter reference

Reference of all the possible values that can be used in page front matter.

## How-to

Applies to pages located under `/app/_how_tos/`.

| Key | Description | Example |
|-----|-------------|---------|
| `title` | (Required) The title of the page. Can be any string. | `title: Add Correlation IDs to logs` | 
| `content_type` | (Required) Specifies the type of content. Must be `how_to`. | `content_type: how_to` |
| `breadcrumbs` | (Optional) Array of URLs to use as breadcrumbs, in ascending order. Each item in the array renders as a different breadcrumb. <br> If not specified, the breadcrumb defaults to "How-to Guides".| <pre>breadcrumbs:<br>  - /gateway/<br>  - /gateway/entities/</pre>|
| `permalink` | (Optional) URL to override the default one for the page (default is the file path after `app`). | `permalink: /gateway/get-started/` to replace the default value of `/how-to/gateway-get-started/` |
| `description` | (Required) Brief description of what the page covers. | `description: Learn how to add correlation IDs to logs with the Correlation ID plugin.` |
| `tools` | (Required) Array of tools mentioned or used in the guide.  Can be one or more of:<br> - deck<br>- admin-api<br>- konnect-api<br>- kic<br>- terraform | <pre>tools:<br>  - deck</pre> |
| `products` | (Required) Array of products that the guide applies to. The first item in the array determines which product index this page links to. Can be one or more of: `gateway`, `ai-gateway`, `dev-portal`, `mesh`, `kic`, `operator`, `insomnia`, `observability`, `service-catalog`, `event-gateway`, `konnect-platform`, `reference-platform`  | <pre>products:<br>  - gateway</pre> |
| `works_on` | (Required) Array of deployment environments where this applies. Can be `on_prem` or `konnect`. | <pre>works_on:<br>  - konnect<br>  - on-prem</pre> |
| `tags` | (Optional) Array of tags for organizing content. | <pre>tags:<br>  - transformations<br>  - logging</pre> | 
| `plugins` | (Optional) Array of plugins referenced in the guide. | <pre>plugins:<br>  - correlation-id<br>  - rate-limiting</pre> | 
| `related_resources` | (Optional) Array of links to related documentation. Takes the following attributes:<br>  - `text`: The title of the linked page.<br>  - `url`: The link to the page. | <pre>related_resources:<br>  - text: "{{site.base_gateway}} logs"<br>    url: /gateway/logs/</pre> | 
| `tldr` | (Required) Short question and answer summary of the guide. Takes the following attributes:<br>  - `q`: The question, which is hidden from the page but appears in search results.<br>  - `a`: The answer, which displays as the short description at the top of the page. | <pre>tldr:<br>  q: How do I add Correlation IDs to my logs?<br>  a: Define log format and reference header</pre> | 
| `prereqs` | (Optional) Array of prerequisites needed before following the guide. Accepts a file reference or an inline entry. | See [prereqs](#example-of-how-to-prereqs) for an example and options.  |
| `cleanup` | (Optional) Array of steps to clean up your environment after completing the guide. Accepts a file reference or an inline entry. | See [cleanup](#example-of-how-to-cleanup) for an example and options. | 
| `min_version` | (Optional) Minimum version requirement. | <pre>min_version:<br>  gateway: '3.4'</pre> |
| `premium_partner` | (Optional) Marks a page with a premium partner label. | `premium_partner: true` |
| `beta` | (Optional) Adds a beta label/banner to the page. | `beta: true` |
| `tech_preview` | (Optional) Adds a tech preview label/banner to the page. | `tech_preview: true` |
| `faqs` | (Optional) Array of FAQ entries in `q:` and `a:` format. Takes the following attributes:<br>  - `q`: The question displayed as the title of the collapsed section.<br>  - `a`: The answer, which is hidden in a collapsible section. | <pre>faqs:<br>  - q: What if I have a question?<br>    a: You get this answer.</pre> |
| `series` | (Optional) Marks this page as part of a series. Takes the following attributes:<br> - `id`: Series ID, e.g. `custom-dashboards`. All items in a specific series must have the same ID.<br>  - `position`: The order this page comes in in the series, e.g. `1`. | <pre>series:<br>  id: custom-dashboards<br>  position: 1</pre>
| `automated_tests` | (Optional) Specifies whether automated tests should run on this page. Default is `true`, set to `false` to disable on any page that can't be tested programmatically. | `automated_tests: false` |

Look at any how-to under [`app/_how_tos/`](https://github.com/Kong/developer.konghq.com/tree/main/app/_how-tos) for examples.

### Example of how-to prereqs

You can find all prereq options under [`app/_includes/prereqs/`](https://github.com/Kong/developer.konghq.com/tree/main/app/_includes/prereqs). 

```yaml
prereqs:
  skip_product: true | false  # If set to true, skips the product installation prereq; false by default
  show_works_on: true | false # If set to false, skips the instructions for Konnect PAT. Useful for ; true by default
  inline: # text or references to a file
    - title: Enable Keyring
      position: before # Positions this prereq before the product installation prereq
      content: |
          Before configuring this plugin, you must enable {{site.base_gateway}}'s encryption [Keyring](/gateway/keyring).
      icon_url: /assets/icons/keyring.svg
    - title: "{{site.base_gateway}} license"
      include_content: prereqs/gateway-license
      icon_url: /assets/icons/gateway.svg
  konnect: #Sets kong.conf parameters when running the Konnect DP container in the prereqs 
    - name: KONG_PARAM
      value: 'value to set'
  entities: # References predefined gateway entities
    services:
        - example-service
    routes:
        - example-route
    kubernetes: 
      gateway_api: true # Renders a section in the prereq to enable the Gateway API
      skip_proxy_ip: true # Skips setting the Proxy IP
      gateway_custom_env: # Adds variables when running KIC in Konnect in the prereqs
        AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
  cloud: # Renders a prereq for AWS
    aws:
      secret: true
```

### Example of how-to cleanup

You can find all cleanup options under [`app/_includes/cleanup/`](https://github.com/Kong/developer.konghq.com/tree/main/app/_includes/cleanup).

```yaml
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
```

## Plugin or policy overview

Applies to pages located under:
* [`/app/_kong_plugins/<plugin_name>/index.md`](https://github.com/Kong/developer.konghq.com/tree/main/app/_kong_plugins)
* [`/app/_mesh_policies/<policy_name>/index.md`](https://github.com/Kong/developer.konghq.com/tree/main/app/_mesh_policies)

| Key | Description | Example |
|-----|-------------|---------|
| `title` | (Required) The title of the page. Should be the plugin or policy name. | `title: 'AI Azure Content Safety'` | 
| `name` | (Required) The official plugin or policy name. The title and name are usually the same. | `name: 'AI Azure Content Safety'` |
| `publisher` | (Required)  Either `kong-inc` or the name of a third-party, for community plugins. | `publisher: kong-inc` |
| `tier` | (Optional) Sets the subscription tier requirement. Can be one of `enterprise` or `ai_gateway_enterprise`. | `tier: ai_gateway_enterprise` |
| `content_type` | (Required) Specifies the type of content. Must be `plugin` for Kong plugins, or `policy` for Mesh policies. | `content_type: plugin` |
| `min_version` | (Optional) Minimum version requirement. This is the version the plugin or policy was introduced in. | <pre>min_version:<br>  gateway: '3.4'</pre> |
| `max_version` | (Optional) Maximum version. Set this if the plugin or policy was deprecated or removed. | <pre>max_version:<br>  gateway: '3.8'</pre> |
| `description` | (Required) Brief description of what the page covers. | `description: Learn how to add correlation IDs to logs with the Correlation ID plugin.` |
| `products` | (Required) Array of products that the plugin or policy applies to. The first item in the array determines which product index this page links to. Can be one or more of: `gateway`, `ai-gateway`, `mesh` | <pre>products:<br>  - gateway</pre> |
| `works_on` | (Required) Array of deployment environments where this applies. Can be `on_prem` or `konnect`. | <pre>works_on:<br>  - konnect<br>  - on-prem</pre> |
| `tags` | (Optional) Array of tags for organizing content. | <pre>tags:<br>  - transformations<br>  - logging</pre> | 
| `categories` | (Plugins only; required) Array of categories the plugin fits under. For Kong plugins, there should only be one. This category should match the category in the UI.<br>Possible categories: `ai`, `analytics-monitoring`, `logging`, `security`, `serverless`, `traffic-control`, `transformations`. <br><br> > **Note:** For third-party plugins, omit the category. | <pre>tags:<br>  - transformations</pre> | 
| `related_resources` | (Optional) Array of links to related documentation. | <pre>related_resources:<br>  - text: "{{site.base_gateway}} logs"<br>    url: /gateway/logs/</pre> | 
| `topologies` | (Plugins only; required) Contains the nested keys `on_prem` and `konnect`. Lists the deployment topologies that the plugin can be run in. <br> - `on_prem` can contain `hybrid`, `traditional`, and `db-less`<br>- `konnect` can contain `serverless`, `cloud-gateways`, and `hybrid` | <pre>topologies:<br>  on_prem:<br>    - hybrid<br>    - db-less<br>    - traditional<br>  konnect_deployments:<br>    - hybrid<br>    - cloud-gateways<br>    - serverless</pre> |
| `notes` | (Plugins only; optional) Any notes on deployment topologies or types, if the plugin has any limitations in a particular topology or deployment. | <pre>notes: \|<br>  Dedicated Cloud Gateways: If you use the IAM assumeRole functionality with this plugin, it must be configured differently than for hybrid deployments in Konnect.</pre> |
| `icon` | (Required) Filename of plugin icon. See all [plugin icons](https://github.com/Kong/developer.konghq.com/tree/main/app/assets/icons/plugins). | `icon: ai-azure-content-safety.png` |
| `search_aliases` | (Optional) Search aliases for the search bar and the plugins filter at `/plugins/`. | <pre>search_aliases:<br>  - ai<br>  - llm</pre> |
| `premium_partner` | (Optional) Marks a page with a premium partner label. | `premium_partner: true` |
| `beta` | (Optional) Adds a beta label/banner to the page. | `beta: true` |
| `tech_preview` | (Optional) Adds a tech preview label/banner to the page. | `tech_preview: true` |
| `faqs` | (Optional) Array of FAQ entries in `q:` and `a:` format. Takes the following attributes:<br>  - `q`: The question displayed as the title of the collapsed section.<br>  - `a`: The answer, which is hidden in a collapsible section. | <pre>faqs:<br>  - q: What if I have a question?<br>    a: You get this answer.</pre> |

## Plugin or policy example

Applies to pages located under:
* `/app/_kong_plugins/<plugin_name>/examples/`
* `/app/_mesh_policies/<policy_name>/examples/`

| Key | Description | Example |
|-----|-------------|---------|
| `title` | (Required) The title of the page. This will appear in the table of contents for the plugin examples. | `title: 'Only allow messages about a specific topic'` | 
| `description` | (Required) Brief description of the example. This will appear in search results. Must not contain any markdown or HTML formatting. | `description: Learn how to add correlation IDs to logs with the Correlation ID plugin.` |
| `extended_description` | (Optional) Extended description of the example. This description will display on the page, and can have any markdown or HTML formatting, including links. | <pre>extended_description: \|<br>  Only allow messages about a specific topic. For example, only allow messages about DevOps. <br><br> For a detailed walkthrough, see [Use AI Semantic Prompt Guard plugin to govern your LLM traffic](/how-to/use-ai-semantic-prompt-guard-plugin/).</pre> |
| `min_version` | (Optional) Minimum version requirement. This is the version the functionality was introduced in. | <pre>min_version:<br>  gateway: '3.4'</pre> |
| `max_version` | (Optional) Maximum version. Set this if the functionality was deprecated or removed. | <pre>max_version:<br>  gateway: '3.8'</pre> |
| `weight` | (Required) Determines the order of the table of contents. Items with a higher weight will display before items with a lower weight. | `weight: 900` |
| `requirements` | (Optional) Anything users need to do before running the example. Should omit "obvious" requirements, such as "Kong Gateway must be running". | <pre>requirements:<br>  - "[AI Proxy plugin](/plugins/ai-proxy/) or [AI Proxy Advanced plugin](/plugins/ai-proxy-advanced/) configured with an LLM service."<br>  - "A [Redis](https://redis.io/docs/latest/) instance."</pre> |
| `variables` | (Optional) Environment variables used in the plugin example. | See [variables](#example-of-variables) for an example. |
| `config` | (Required) The full declarative config of the plugin. | See any plugin, such as [AI Azure Content Safety](https://github.com/Kong/developer.konghq.com/blob/main/app/_kong_plugins/ai-azure-content-safety/examples/block-predefined-categories.yaml). | 
| `tools` | (Required) The formats to display the example in. | <pre>tools:<br>  - deck<br>  - admin-api<br>  - konnect-api<br>  - kic<br>  - terraform</pre> |
| `beta` | (Optional) Adds a beta label/banner to the page. | `beta: true` |
| `tech_preview` | (Optional) Adds a tech preview label/banner to the page. | `tech_preview: true` |

### Example of variables

```yaml
variables:
  header_value: # the exact env variable name used in the config
    value: $OPENAI_API_KEY # the display value
    description: Your OpenAI API key # description to show in the doc
  redis_host:
    value: $REDIS_HOST
    description: The host where your Redis instance runs
```

## Reference

> **Note:** This does **not** refer to pages under `/app/_reference`. Those references are auto-generated.

Can apply to any page under `/app/`. Usually contained in a subfolder, such as `/app/gateway/`.

| Key | Description | Example |
|-----|-------------|---------|
| `title` | (Required) The title of the page. Can be any string. | `title: Data plane reference` | 
| `content_type` | (Required) Specifies the type of content. Must be `reference` or `policy`. Use `reference` in most cases. You can also set `content_type: policy` to remove the edit link - this is meant for official support policies and similar pages. | `content_type: reference` |
| `layout` | (Required) Specifies the layout layout for the page.  | `layout: reference` |
| `breadcrumbs` | (Required) Array of URLs to use as breadcrumbs, in ascending order. Each item in the array renders as a different breadcrumb.| <pre>breadcrumbs:<br>  - /gateway/<br>  - /gateway/entities/</pre>|
| `permalink` | (Optional) URL to override the default one for the page (default is the file path after `app`). | `permalink: /gateway/get-started/` to replace the default value of `/how-to/gateway-get-started/` |
| `description` | (Required) Brief description of what the page covers. | `description: Reference for data planes in Konnect.` |
| `products` | (Required) Array of products that the guide applies to. The first item in the array determines which product index this page links to. Can be one or more of: `gateway`, `ai-gateway`, `dev-portal`, `mesh`, `kic`, `operator`, `insomnia`, `observability`, `service-catalog`, `event-gateway`, `konnect-platform`, `reference-platform`  | <pre>products:<br>  - gateway</pre> |
| `works_on` | (Required) Array of deployment environments where this applies. Can be `on_prem` or `konnect`. | <pre>works_on:<br>  - konnect<br>  - on-prem</pre> |
| `tags` | (Optional) Array of tags for organizing content. | <pre>tags:<br>  - transformations<br>  - logging</pre> | 
| `related_resources` | (Optional) Array of links to related documentation. | <pre>related_resources:<br>  - text: "{{site.base_gateway}} logs"<br>    url: /gateway/logs/</pre> | 
| `min_version` | (Optional) Minimum version requirement. | <pre>min_version:<br>  gateway: '3.4'</pre> |
| `max_version` | (Optional) Maximum version. Set this if the functionality was deprecated or removed. | <pre>max_version:<br>  gateway: '3.8'</pre> |
| `act_as_plugin` | (Optional) If set to true, the page will be added to the plugin hub. If using this option, make sure to configure all other plugin metadata as defined in the [plugins](#plugin-or-policy-overview) section. | `act_as_plugin: true` |
| `premium_partner` | (Optional) Marks a page with a premium partner label. | `premium_partner: true` |
| `beta` | (Optional) Adds a beta label/banner to the page. | `beta: true` |
| `tech_preview` | (Optional) Adds a tech preview label/banner to the page. | `tech_preview: true` |
| `faqs` | (Optional) Array of FAQ entries in `q:` and `a:` format. Takes the following attributes:<br>  - `q`: The question displayed as the title of the collapsed section.<br>  - `a`: The answer, which is hidden in a collapsible section. | <pre>faqs:<br>  - q: What if I have a question?<br>    a: You get this answer.</pre> |

## Landing page

Applies to pages located under [`/app/_landing_pages/`](https://github.com/Kong/developer.konghq.com/tree/main/app/_landing_pages).

The following content is nested under the `metadata` key:

| Key | Description | Example |
|-----|-------------|---------|
| `title` | (Required) The title of the page. Can be any string. | `title: decK` | 
| `content_type` | (Required) Specifies the type of content. Must be `reference`. | `content_type: reference` |
| `breadcrumbs` | (Required) Array of URLs to use as breadcrumbs, in ascending order. Each item in the array renders as a different breadcrumb.| <pre>breadcrumbs:<br>  - /gateway/<br>  - /gateway/entities/</pre>|
| `products` | (Required) Array of products that the page applies to. The first item in the array determines which product index this page links to. Can be one or more of: `gateway`, `ai-gateway`, `dev-portal`, `mesh`, `kic`, `operator`, `insomnia`, `observability`, `service-catalog`, `event-gateway`, `konnect-platform`, `reference-platform`  | <pre>products:<br>  - gateway</pre> |
| `search_aliases` | (Optional) Search aliases for the search bar and the plugins filter at `/plugins/`. | <pre>search_aliases:<br>  - ai<br>  - llm</pre> |
| `tags` | (Optional) Array of tags for organizing content. | <pre>tags:<br>  - transformations<br>  - logging</pre> | 
| `beta` | (Optional) Adds a beta label/banner to the page. | `beta: true` |
| `tech_preview` | (Optional) Adds a tech preview label/banner to the page. | `tech_preview: true` |

The body of the page is contained in a `rows` key. See [landing page blocks](https://developer.konghq.com/contributing/#landing-page-blocks) for more information.
