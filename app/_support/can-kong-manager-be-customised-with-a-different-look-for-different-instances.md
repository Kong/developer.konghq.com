---
title: Customizing Kong Manager's appearance per instance with login, header, and footer banners
content_type: support
description: Kong Manager supports setting custom text messages for 3 places; login message, header banner and footer banner.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Can Kong Manager be customised with a different look for different instances?
  a: |
    Kong Manager supports custom banner text and colors for three places — the login screen, and a header/footer bar — set via variables like `KONG_ADMIN_GUI_LOGIN_BANNER_TITLE`, `KONG_ADMIN_GUI_HEADER_TXT`, and `KONG_ADMIN_GUI_HEADER_BG_COLOR`. This is commonly used to visually distinguish Dev/Test/Prod instances that share similar URLs.
related_resources:
  - text: Kong Manager configuration parameters documentation
    url: /gateway/configuration/#admin-gui-header-txt
---

## Customizing Kong Manager's appearance per instance

What are the options available to edit the appearance of Kong Manager? For example, it is required to customize Kong Manager to add some visual cues per environment? This is especially important in the case of differentiating between different instances (Dev, Test, Prod, etc) that might have similar URLs leading to confusion on which environment is being accessed.

It is possible to set custom text messages for 3 places; login message, header banner and footer banner for Kong Manager. The login message can have a title and message (for example a warning message against unauthorized access) and the header and footer can have individual text content as well as the foreground and background colors can be specified.

You can read more about the available parameters in the documentation.

For example, setting the below parameters in the Kong configuration;

```yaml

KONG_ADMIN_GUI_LOGIN_BANNER_TITLE: "Limited Access"
KONG_ADMIN_GUI_LOGIN_BANNER_BODY: "Access by unauthorised personnel is prohibited"
KONG_ADMIN_GUI_HEADER_TXT: "*** PRODUCTION environment ***"
KONG_ADMIN_GUI_HEADER_BG_COLOR: "green"
KONG_ADMIN_GUI_HEADER_TXT_COLOR: "white"
```

will display this on the login screen;

and after login, Kong Manager will have a green bar at the top showing the environment name;
