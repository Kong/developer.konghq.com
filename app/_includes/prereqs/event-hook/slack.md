To create an Event Hook that pushes information to Slack, you will need to configure some options in Slack.

1. Create an application in [Slack](https://api.slack.com/apps?new_app=1)
2. From the application select **Incoming Webhooks** and activate incoming webhooks.
3. Add a new webhook and select a Slack channel.
4. Copy the **Webhook URL** from the Slack application dashboard and set it as an environment variable:

   ```sh
   export SLACK_WEBHOOK_URL='WEBHOOK URL`
   ```