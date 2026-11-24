# Konnect organization notification events

Fetches the organization event types available to the configured stable
{{site.konnect_short_name}} organization and writes them to
`app/_data/konnect_notification_events.json` for the Notification Hub reference.

## Refresh the docs data

Use an organization administrator personal access token for the stable
organization:

```sh
KONNECT_TOKEN=<organization-admin-token> node tools/konnect-notification-events/fetch-events.js
```

The script calls `GET https://global.api.konghq.com/v1/notifications/configurations/organization`, sorts the returned events by namespace and title, and writes their event type, title, description, and namespace. The token is used only for the request and is not written to disk.

For a non-production Konnect domain or API host, set `KONNECT_API_BASE_URL` to the API base URL ending in `/v1`.

The GitHub Actions workflow runs weekly and can also be started manually. It
uses the repository `KONNECT_TOKEN` secret for the stable organization and
opens or updates a pull request when the generated event list changes.
