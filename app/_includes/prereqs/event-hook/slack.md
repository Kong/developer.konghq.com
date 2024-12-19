To create an event hook that pushes information to Slack you will need to configure some options in Slack.

1. Create an application in [Slack](https://api.slack.com/apps?new_app=1)
2. From the application select **Incoming Webhooks** and activate incoming webhooks.
3. Copy the **Webhook URL** from the Slack application dashboard and set it as an environment variable: 
    `export SLACK_WEBHOOK_URL=<webhook-url>`
4. In Slack, add your application to a channel.

