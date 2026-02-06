---
title: Datakit flow editor

content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem
    - konnect

no_version: true

breadcrumbs:
  - /gateway/datakit/

description: "Explains how to use the Datakit flow editor in the {{site.konnect_short_name}} UI"

related_resources:
  - text: Datakit overview
    url: /gateway/datakit/
  - text: Datakit plugin reference
    url: /plugins/datakit/

faqs:
  - q: I've configured a call node in the response section, why is it throwing an error?
    a: |
      In {{site.base_gateway}} 3.12 and earlier, the `call` node couldn't be executed after proxying a request, and you would see the following error:

      ```
      invalid dependency (node #1 (CALL) -> node service_response): circular dependency
      ```

      This means that your data planes are running {{site.base_gateway}} 3.12 or earlier. 
      Upgrade your data planes to 3.13 to use this functionality.
---

In addition to the standard [{{site.base_gateway}} configuration tools](/tools/),
{{site.konnect_short_name}} provides a drag-and-drop flow editor for Datakit. 
The flow editor helps you visualize node connections, inputs, and outputs.

![Full screen flow editor](/assets/images/konnect/datakit-flow-editor-node.png)
> _Figure 1: The Datakit flow editor opens in a full screen with a list of nodes, a drag-and-drop diagram, and detailed configuration options for each node._

You can find the flow editor in the Datakit plugin's configuration page in {{site.konnect_short_name}}.
From here, you can configure Datakit in one of two ways:
* Using the visual flow editor
* Using the code editor

Any changes you make in one editor are reflected in the other. 
For instance, if you have a YAML configuration for Datakit that you want to visualize, you can add it to the code editor, then switch to the flow editor to see it in flow format.

![Flow editor preview](/assets/images/konnect/datakit-flow-editor-preview.png)
> _Figure 2: Toggle the Datakit plugin configuration to the Flow Editor to edit configuration using drag-and-drop. The flow editor shows a preview of the diagram, which you can click to edit in a full screen._

![Code editor](/assets/images/konnect/datakit-code-editor.png)
> _Figure 3: Toggle the Datakit plugin configuration to the Code Editor to edit configuration in YAML format._

### Using the Datakit flow editor 

To configure Datakit using the flow editor:

1. In the {{site.konnect_short_name}} sidebar, navigate to [API Gateway](https://cloud.konghq.com/gateway-manager/). 
1. Click your control plane. 
1. In the API Gateway sidebar, click **Plugins**.  
1. Click **New Plugin**.
1. Click **Datakit**.
1. In the Plugin Configuration section, click **Go to flow editor**.
1. In the editor, drag any node from the menu onto the canvas to add it to your flow, or click **Examples** and choose a pre-configured example to customize.
1. Expand the `inputs` or `outputs` on a node to see the options, then connect a specific input or output to another node.
1. Select any node to open its detailed configuration in a slide-out menu.
1. Fill out the configuration. Any changes to inputs or outputs will be reflected in the diagram.
1. Click **Done**.

{:.info}
> **Notes:** 
* Each input can connect to only one output, but one output can accept many inputs.
* Your nodes don't have to connect to the prepopulated `request`/`service request` or `response`/`service response` nodes. 
Whether you need them or not depends on your use case. Check out the **Examples** dropdown in the editor for some variations.