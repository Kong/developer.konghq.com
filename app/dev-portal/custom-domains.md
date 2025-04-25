---
title: Custom domains
content_type: reference
layout: reference

products:
    - dev-portal

works_on:
    - konnect

description: "{{site.konnect_short_name}} integrates domain name management and configuration in Settings. Select your Dev Portal and click Settings to view your configuration."

related_resources:
  - text: Portal customization reference
    url: /dev-portal/portal-customization/
  - text: Custom pages
    url: /dev-portal/custom-pages/
  - text: Dev Portal settings
    url: /dev-porta/portal-settings/
faqs:
  - q: What is the difference between Beta and previous Dev Portal URLs?
    a: |
      Beta Dev Portals include `edge` before the region in the default URL (for example, `example.edge.us.portal.konghq.com`), 
      whereas previous Dev Portals don't.

  - q: How do I delete a custom domain from a Dev Portal?
    a: |
      To delete a custom domain, go to your Dev Portal, click **Settings**, then click the trash/delete icon next to the domain entry.

  - q: What should I do if my custom Dev Portal domain shows an SSL error?
    a: |
      After DNS verification, {{site.konnect_short_name}} will attempt to auto-generate an SSL certificate. 
      This process may take several hours. If you try to access the custom domain before the certificate is ready, you may see an SSL error.

      If the process takes more than 24 hours, check that your DNS record has propagated correctly.

  - q: How do I troubleshoot DNS for my custom Dev Portal domain?
    a: |
      Use the `dig` command to verify DNS configuration. Replace `CUSTOM_DOMAIN` and `CUSTOM_DOMAIN_DNS` with your actual values:
      ```sh
      dig +nocmd @CUSTOM_DOMAIN_DNS cname CUSTOM_DOMAIN +noall +answer
      ```

      The output should show something like:
      ```
      portal.example.com. 172 IN CNAME example.edge.us.portal.konghq.com.
      ```

      This confirms that your custom domain points to the expected default domain.
---

Every Dev Portal instance has an auto-generated default URL. You can also manage custom URLs within {{site.konnect_short_name}}.
This gives users the ability to access the Dev Portal from either the default URL, for example `https://example.edge.us.portal.konghq.com`, or a custom URL like `portal.example.com`.

To add a custom URL to Dev Portal, you need:

* A domain and access to configure the domain's DNS `CNAME` records
* Your organization's auto-generated default Dev Portal URL
* A [CAA DNS](https://datatracker.ietf.org/doc/html/rfc6844) record that only allows `pki.goog` if any pre-existing CAA DNS records are present on the domain

## Configure DNS

In your DNS configuration, create a CNAME record for the domain you want to use using the automatically generated Dev Portal URL.
The record will look like this:

{% table %}
columns:
  - title: Type
    key: type
  - title: Name
    key: name
  - title: Value
    key: value
rows:
  - type: CNAME
    name: portal
    value: "`https://example.edge.us.portal.konghq.com`"
{% endtable %}

If your domain has specific CAA DNS records that list authorized certificate authorities/issuers, you'll also need to create a new CAA DNS record to permit [Google Trust Services](https://pki.goog/faq/#caa) as an issuer. 
If your domain doesn't currently have any CAA DNS records, it means all issuers are implicitly allowed, and there's no need for a new CAA DNS record in that case.

## Update Dev Portal URL settings {#update-portal}

To add a custom URL to Dev Portal, select your Dev Portal, click **Settings**, then follow these steps:

1. Select **Custom hosted domain**.

2. Enter the fully qualified domain name (FQDN) including the subdomain, if applicable, into the **Custom Domain** field.
   Don't include a path or protocol (e.g. `https://`).

3. Click **Save Changes**.

4. CNAME status and SSL status will show `Pending`, while the DNS record TTL expires and SSL is configured. The status of these changes will update as they have been completed.

## Domain name restrictions

Because of SSL certificate authority restrictions, {{site.konnect_short_name}} can't generate SSL certificates
for the following domains:

* TLDs containing a brand name: `.aws`, `.microsoft`, `.ebay`
* Hosting provider subdomains: `.amazonaws.com`, `.azurewebsites.net`
* TLDs restricted by US export laws:
  * `.af` Afghanistan
  * `.by` The Republic of Belarus
  * `.cu` Cuba
  * `.er` Eritrea
  * `.gn` Guinea
  * `.ir` Islamic Republic of Iran
  * `.kp` Democratic People's Republic of Korea
  * `.lr` Liberia
  * `.ru` The Russian Federation
  * `.ss` South Sudan
  * `.su` Soviet Union
  * `.sy` Syrian Arab Republic
  * `.zw` Zimbabwe

If you have any questions, [contact Support](https://support.konghq.com).