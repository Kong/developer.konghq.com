---
title: Hooks and actions

description: Hooks and actions allow you to add additional functionality to your custom plugins through requests, responses, and UI interactions.

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/
- /insomnia/plugins/

tags:
- plugins

search_aliases:
  - Insomnia plugins
  - Insomnia custom plugins
related_resources:
  - text: Plugins
    url: /insomnia/plugins/
  - text: Plugin reference
    url: /insomnia/plugins/plugin-reference/
  - text: Context object reference
    url: /insomnia/plugins/context-object-reference/
---
Hooks and actions allow you to add additional functionality to your custom plugins through requests, responses, and UI interactions. Hooks rely on a request or response. Actions rely on a UI interaction.

## Request and response hooks

Plugins can implement hook functions that get called when certain events happen. A plugin can currently export two different types of hooks, `RequestHook` and `ResponseHook`.

```ts
interface RequestHook {
    app: AppContext;
    request: Request;
};

interface ResponseHook {
    app: AppContext;
    response: Response;
}

// Hooks are exported as an array of hook functions that get 
// called with the appropriate plugin API context.
module.exports.requestHooks = Array<(context: RequestHook) => void>;
module.exports.responseHooks = Array<(context: ResponseHook) => void>;
```

## Request actions

Actions can be added to the bottom of the request dropdown context menu (right click on a request in the sidebar) by defining a request action plugin.

```ts
interface RequestAction {
    label: string;
    action: (context: Context, models: { 
        requestGroup: RequestGroup;
        request: Request;
    }): void | Promise<void>;
    icon?: string;
};

// Request actions are exported as an array of objects
module.exports.requestActions = Array<RequestAction>
```

### Request action examples

Adds a **See request data** option to the dropdown menu that appears when you right-click on a request in the sidebar:

```ts
module.exports.requestActions = [
  {
    label: 'See request data',
    action: async (context, data) => {
      const { request } = data;
      const html = `<code>${JSON.stringify(request)}</code>`;
      context.app.showGenericModalDialog('Results', { html });
    },
  },
];
```

Adds a **Send request** option to the dropdown menu that appears when you right-click on a request in the sidebar:

```ts
module.exports.requestActions = [
  {
    label: "Send request",
    action: async (context, data) => {
      const { request } = data;
      const response = await context.network.sendRequest(request);
      const html = `<code>${request.name}: ${response.statusCode}</code>`;
      context.app.showGenericModalDialog("Results", { html });
    },
  },
];
```

## Folder actions

Actions can be added to the bottom of the folder dropdown menu by defining a folder (request group) action plugin.

```ts
interface RequestGroupAction {
    label: string;
    action: (context: Context, models: { 
        requestGroup: RequestGroup; 
        requests: Array<Request>;
    }): Promise<void>;
};

// Folder actions are exported as an array of objects
module.exports.requestGroupActions = Array<RequestGroupAction>
```

### Folder action examples

Adds a **Send Requests** option to the dropdown menu that appears when you click on a request folder. **Send Requests** sends all requests in that folder at once:

```ts
module.exports.requestGroupActions = [
  {
    label: 'Send Requests',
    action: async (context, data) => {
      const { requests } = data;

      let results = [];
      for (const request of requests) {
        const response = await context.network.sendRequest(request);
        results.push(`<li>${request.name}: ${response.statusCode}</li>`);
      }

      const html = `<ul>${results.join('\n')}</ul>`;

      context.app.showGenericModalDialog('Results', { html });
    },
  },
];
```

## Workspace actions

Actions can be added to the collection or document settings dropdown by defining a workspace action plugin. These apply to both types of workspaces, Request Collections and Design Documents.

{:.info}
> **Note**: "Workspace" is a name in our codebase that we use to refer to both documents and collections.

```ts
interface WorkspaceAction {
    label: string;
    action: (context: Context, models: { 
        workspace: Workspace;
        requestGroup: Array<RequestGroup>,;
        requests: Array<Request>;
    }): Promise<void>;
};

// Workspace actions are exported as an array of objects
module.exports.workspaceActions = Array<WorkspaceAction>;
```

### Workspace action examples

Add a custom option to the document or collection dropdown menu that exports the current document or collection:
```ts
const fs = require('fs');

module.exports.workspaceActions = [{
  label: 'My Plugin Action',
  icon: 'fa-star',
  action: async (context, models) => {
    const ex = await context.data.export.insomnia({
      includePrivate: false,
      format: 'json',
      workspace: models.workspace,
    });

    fs.writeFileSync('./export.json', ex);
  },
}];
```

## Document actions

Actions can be added to a dashboard card context menu for a document. This action does not work for collections.

```ts
interface DocumentAction {
    label: string,
    action: (
      context: Context,
      spec: {
        contents: Record<string, any>;
        rawContents: string;
        format: string;
        formatVersion: string;
      }
    ): void | Promise<void>;
    hideAfterClick?: boolean;
};

// Document actions are exported as an array of objects
module.exports.documentActions = Array<DocumentAction>;
```
