---
title: "Keyboard shortcuts for Insomnia"
content_type: reference
layout: reference
breadcrumbs:
  - /insomnia/

products:
  - insomnia

search_aliases: 
  - Tips
  - Keyboard shortcuts
description: Learn about keyboard shortcuts you can use in the Insomnia desktop application.
related_resources:
  - text: Requests in Insomnia
    url: /insomnia/requests/
  - text: Environments
    url: /insomnia/environments/
---
Insomnia offers a wide range of keyboard shortcuts that help you navigate faster, write requests efficiently, and switch contexts with minimal friction. Using keyboard shortcuts, you can do the following:
* Edit, build, and execute complex HTTP requests
* Manage multiple environments
* Navigate through the Insomnia UI

You can view and manage your keyboard shortcut bindings in Insomnia by navigating to **Preferences** at the bottom left of the sidebar, and then clicking the **Keyboard** tab.


## Navigation and UI controls
Use these shortcuts to help you quickly move around the Insomnia interface, toggle panels, and access essential settings.
{% table %}
columns:
  - title: Shortcuts
    key: shortcut
  - title: Action
    key: action
  - title: Description
    key: description    
rows:
  - shortcut: |
      Windows: `Ctrl + Shift + ,` <br>
      Mac: `⇧ ⌘ ,`
    action: "Show document/collection settings"
    description: Open settings for the current document or collection.
  - shortcut: |
      Windows: `Ctrl + Alt + Shift + ,` <br>
      Mac: `⌥ ⇧ ⌘ ,`
    action: "Show request settings"
    description: Open the settings for the currently selected request.
  - shortcut: |
      Windows: `Ctrl + Shift + /` <br>
      Mac: `⌃ ⇧ ⌘ /`
    action: "Show keyboard shortcuts"
    description: Display a list of all available keyboard shortcuts.
  - shortcut: |
      Windows: `Ctrl + ,` <br>
      Mac: `⌘ ,`
    action: "Show app preferences"
    description: Open the global preferences dialog.
  - shortcut: |
      Windows: `Ctrl + P` <br>
      Mac: `⌘ P`
    action: "Quick search"
    description: Open the quick switcher to search requests and environments.
  - shortcut: |
      Windows: `Ctrl + Shift + R` <br>
      Mac: `⇧ ⌘ R`
    action: "Reload plugins"
    description: Reload all active Insomnia plugins.
  - shortcut: |
      Windows: `Ctrl + Space` <br>
      Mac: `⌃ Space`
    action: "Show autocomplete"
    description: Activate autocomplete suggestions in the editor.
  - shortcut: |
      Windows: `Ctrl + Shift + H` <br>
      Mac: `⇧ ⌘ H`
    action: "Show request history"
    description: Display the full history of sent requests.
  - shortcut: |
      Windows: `Ctrl + Shift + F` <br>
      Mac: `⇧ ⌘ F`
    action: "Filter sidebar"
    description: Filter the request list in the sidebar.
  - shortcut: |
      Windows: `Ctrl + \` <br>
      Mac: `⌘ \`
    action: "Toggle sidebar"
    description: Show or hide the left-hand request sidebar.
  - shortcut: |
      Windows: `Ctrl + '` <br>
      Mac: `⌘ '`
    action: "Focus response"
    description: Select the content in the response pane.
  - shortcut: |
      Windows: `Ctrl + Shift + I` <br>
      Mac: `⇧ ⌘ I`
    action: "Focus graphQL explorer filter"
    description: Focus the filter field in the GraphQL explorer.               
{% endtable %}

## Request execution and environment management
Use these shortcuts to send requests, edit or switch environments, and work with variable resolution.
{% table %}
columns:
  - title: Shortcuts
    key: shortcut
  - title: Action
    key: action
  - title: Description
    key: description    
rows:
  - shortcut: |
      Windows: `Ctrl + Enter` or `F5` <br>
      Mac: `⌘ Enter` or `⌘ R` or `F5`
    action: "Send request"
    description: Send the currently active request.
  - shortcut: |
      Windows: `Ctrl + Shift + Enter` <br>
      Mac: `⇧ ⌘ Enter`
    action: "Send request (with options)"
    description: Send request with additional options, such as repeating or adding a delay.
  - shortcut: |
      Windows: `Ctrl + E` <br>
      Mac: `⌘ E`
    action: "Show environment editor"
    description: Open the environment editor to view or edit environment variables.
  - shortcut: |
      Windows: `Ctrl + Shift + E` <br>
      Mac: `⇧ ⌘ E`
    action: "Switch environments"
    description: Open a dialog to switch between predefined environments.
  - shortcut: |
      Windows: `Alt + Shift + U` <br>
      Mac: `⌥ ⇧ U`
    action: "Show variable source and value"
    description: Reveal where a variable is defined and its resolved value at runtime.
{% endtable %}

## Edit and build requests
Use these shortcuts to help you construct HTTP requests faster by giving you quick access to the request method, URL field, code generation tools, and beautification features.
{% table %}
columns:
  - title: Shortcuts
    key: shortcut
  - title: Action
    key: action
  - title: Description
    key: description    
rows:
  - shortcut: |
      Windows: `Ctrl + Shift + L` <br>
      Mac: `⇧ ⌘ L`
    action: "Change HTTP method"
    description: Selects the HTTP method dropdown.
  - shortcut: |
      Windows: `Ctrl + L`<br>
      Mac: `⌘ L`
    action: "Focus URL"
    description: Selects the request URL field.
  - shortcut: |
      Windows: `Ctrl + Shift + G`<br>
      Mac: `⇧ ⌘ G`
    action: "Generate code"
    description: Open the code generation window for the current request in various languages.
  - shortcut: |
      Windows: `Ctrl + Shift + F`<br>
      Mac: `⇧ ⌘ F`
    action: "Beautify active code editors"
    description: Automatically format and beautify structured text, for example, JSON or XML.
  - shortcut: |
      Windows: `Ctrl + K`<br>
      Mac: `⌘ K`
    action: "Edit cookies"
    description: Open the cookie editor for the active domain associated with the request.
{% endtable %}

## Creating, duplicating, and managing requests
Use these shortcuts to help you create, delete, duplicate, and organize your requests into folders.
{% table %}
columns:
  - title: Shortcuts
    key: shortcut
  - title: Action
    key: action
  - title: Description
    key: description    
rows:
  - shortcut: |
      Windows: `Ctrl + N` or `Ctrl + Alt + N`<br>
      Mac: `⌘ N` or `⌥ ⌘ N`
    action: "Create HTTP Request"
    description: Create a new HTTP request in the current workspace.
  - shortcut: |
      Windows: `Ctrl + D`<br>
      Mac: `⌘ D`
    action: "Duplicate request"
    description: Duplicate the currently selected request.
  - shortcut: |
      Windows: `Ctrl + Shift + Backspace`<br>
      Mac: `⇧ ⌘ Backspace`
    action: "Delete request"
    description: Permanently delete the selected request.
  - shortcut: |
      Windows: `Ctrl + Shift + N`<br>
      Mac: `⇧ ⌘ N`
    action: "Create folder"
    description: Add a new folder to the request sidebar.
  - shortcut: |
      Windows: `Ctrl + Shift + P`<br>
      Mac: `⇧ ⌘ P`
    action: "Pin or unpin request"
    description: Pin or unpin a request for quick access in the UI.
{% endtable %}

## Workspace maintenance
Use this shortcut to keep your workspace clean as you wrap up tasks or shift focus.
{% table %}
columns:
  - title: Shortcuts
    key: shortcut
  - title: Action
    key: action
  - title: Description
    key: description    
rows:
  - shortcut: |
      Windows: `Ctrl + W`<br>
      Mac: `⌘ W`
    action: "Close tab"
    description: Close the currently open request tab.
{% endtable %}    