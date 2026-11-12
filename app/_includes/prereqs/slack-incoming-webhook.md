A Slack notification channel posts alerts to an incoming webhook that you create in your own Slack workspace.
{{site.ai_cost_management}} has no Slack app of its own, so you create the webhook from an app in your own workspace.

To create the webhook:

1. Open [Create a Slack app](https://api.slack.com/apps?new_app=1).
1. Select **Blank app**.
1. In the **App name** field, enter a name like `Kong AI Cost Management`.
1. Select the Slack workspace that receives the alerts, then click **Continue**.
1. Set bot scopes to `incoming-webhook`, then click **Continue**.
1. Click **Continue** to skip **What it can respond to**, which you don't need for this example.
1. Click **Create and Install**.
1. In the auth dialog, choose a channel in your workspace.
1. Click **Allow**.
1. Click **Go to App Settings**.
1. Under **Features**, click **Incoming Webhooks**.
1. Copy the **Webhook URL** for your webhook. The webhook URL must start with `https://hooks.slack.com/services/`.
1. Export the webhook URL as an environment variable:

   ```sh
   export SLACK_WEBHOOK_URL='YOUR_SLACK_WEBHOOK_URL'
   ```

{:.warning}
> **Caution**: Anyone with the URL can post to the Slack channel, so store it securely.
