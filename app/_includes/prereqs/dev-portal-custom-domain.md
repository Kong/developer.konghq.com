You need a domain that you control for two purposes:

- Email sending: the domain is registered with the portal's email service so it can send notification emails to developers.
- Custom portal URL: the hostname is mapped to your portal so developers can access it at a predictable address.

Export the following environment variables before running the steps in this guide:

```bash
export PORTAL_EMAIL_DOMAIN='YOUR_DOMAIN'
export PORTAL_FROM_EMAIL="noreply@${PORTAL_EMAIL_DOMAIN}"
export PORTAL_REPLY_TO_EMAIL="support@${PORTAL_EMAIL_DOMAIN}"
export PORTAL_HOSTNAME="portal.${PORTAL_EMAIL_DOMAIN}"
```

For more information, see [{{ site.dev_portal }} custom domains](/dev-portal/custom-domains/).
