---
title: Manage secrets in Insomnia with 1Password
permalink: /how-to/manage-secrets-in-insomnia-with-1password/
content_type: how_to

description: Use the Insomnia 1Password plugin to retrieve secrets from a 1Password vault and use them in your requests.

related_resources:
  - text: 1Password plugin
    url: https://insomnia.rest/plugins/insomnia-plugin-op
  - text: Template tags
    url: /insomnia/template-tags/

products:
    - insomnia

tags:
    - secrets-management
    - 1password

tldr:
    q: How can I integrate 1Password with Insomnia for secrets management?
    a: Install the 1Password CLI. In Insomnia, navigate to **Preferences** > **Plugins**, allow elevated access to plugins, and install the [Insomnia 1Password plugin](https://insomnia.rest/plugins/insomnia-plugin-op). Configure the plugin with the `__op_plugin` environment variable, and use the 1Password [template tag](/insomnia/template-tags/) to fetch a secret.

prereqs:
  inline:
    - title: 1Password
      include_content: prereqs/insomnia-1password
      icon_url: /assets/icons/1password.svg

automated_tests: false

faqs:
  - q: Can I use the 1Password plugin with Inso CLI?
    a: No, currently Insomnia plugins are not supported in Inso CLI.
  - q: Does Insomnia save my 1Password secrets?
    a: No, secrets are cached in memory only and not persisted to disk.
  - q: Why am I getting errors when using the 1Password plugin?
    a: |
        There are a few known issues that may be cause errors with the plugin. Make sure that everything is configured properly:
        * [Integrate 1Password CLI with the 1Password desktop app](https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration).
        * On macOS, set the `cliPath` parameter to the correct path to the 1Password CLI binary, and make sure that the desktop app is set to [run in the background](https://developer.1password.com/docs/cli/app-integration/#if-you-see-a-connection-error).

---

## Enable elevated access for plugins

The 1Password plugin needs to make system-level calls to the local 1Password CLI. To enable this, in Insomnia, navigate to **Preferences** > **Plugins** and select the **Allow elevated access for plugins** checkbox.

## Install the 1Password plugin

Go to the [Insomnia Plugin Hub](https://insomnia.rest/plugins/insomnia-plugin-op) and install the 1Password plugin.

## Configure the plugin

The 1Password plugin is configured through a JSON [environment variable](/insomnia/environments/). This environment variable can be defined with any environment type. In this example, we'll configure it in a global base environment.

1. In your project, click **+ Create** and click **Environment** to create a new global environment.
1. In the base environment disable **Table View** and add the following content, with the correct path and [1Password sign-in address](https://support.1password.com/change-sign-in-address/#change-your-sign-in-address-on-1passwordcom):
   ```json
   {
    "__op_plugin": {
      "cliPath": "/opt/homebrew/bin/op",
      "defaultAccount": "account-name.1password.com"
    }
   }
   ```

   {:.info}
   > **Notes**:
   > * The `cliPath` parameter is the path to the 1Password CLI binary. This parameter is only required on macOS to avoid issues locating 1Password CLI.
   > * The plugin also supports the `cacheTTL` and `flags` parameters. See the [plugin configuration](https://insomnia.rest/plugins/insomnia-plugin-op#configuration) for more details.

## Use a 1Password secret in a request

The 1Password plugin creates a custom [template tag](/insomnia/template-tags/) that you can configure to fetch a secret and use it in multiple places in a request.

1. Create a collection or open an existing one.
1. Click the environments on the left pane and select the global environment containing the 1Password configuration that we created in the previous step.
1. Create a new request. For this example, we'll send a `POST` request to `http://httpbin.konghq.com/anything`.
1. Open the **Body** tab, click **No Body** and select **Form Data**.
1. Enter a parameter name, `secret` for example.
1. Click the **value** field field, press `Control+Space` to display the available template tags, and select **1Password => Fetch Secret**.
1. Click the template tag to configure it, and add the reference to the 1Password secret we created in the [prerequisites](#1password): `op://insomnia/test-secret/password`. The live preview should show `my-password`.
1. Click **Done** to apply the configuration.

## Validate

To validate the configuration, send the request. The response should contain the `secret` field we added:
```json
{
	"args": {},
	"data": "",
	"files": {},
	"form": {
		"secret": "my-password"
	},
	"headers": {
		"Accept": "*/*",
		"Content-Length": "110",
		"Content-Type": "multipart/form-data; boundary=X-INSOMNIA-BOUNDARY",
		"Host": "httpbin.konghq.com",
		"User-Agent": "insomnia/11.3.0"
	},
	"json": null,
	"method": "POST",
	"url": "http://httpbin.konghq.com/anything"
}
```
{:.no-copy-code}
