---
title: Upgrade the kong-harnesses Windows installer with Intune
description: How to move Intune-managed Windows 11 computers to a new kong-harnesses release with a new Win32 app that uses supersedence, and how to clean up the previous release app.
content_type: reference
layout: reference
permalink: /kong-harnesses/upgrade-with-intune/
breadcrumbs:
  - /kong-harnesses/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli
  - azure
  - windows
  - upgrade

related_resources:
  - text: Deploy the kong-harnesses Windows installer with Intune
    url: /kong-harnesses/deploy-with-intune/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Add Win32 app supersedence
    url: https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-supersedence
  - text: Add a Win32 app to Microsoft Intune
    url: https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32
  - text: Monitor apps
    url: https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-monitor
---

Each [kong-harnesses](/kong-harnesses/) release reaches Windows 11 computers managed with [Microsoft Intune](https://learn.microsoft.com/en-us/intune/) as a new Windows app (Win32) that supersedes the app for the previous release.
Installing a newer `.msi` replaces the installed version in place.
Windows Installer refuses an older installer.
Intune therefore doesn't need to uninstall the previous version first.

The following sections give the supersedence settings and the checks that confirm an upgrade.
The linked Microsoft documentation covers the Intune interface.

## How the upgrade works

A new app doesn't copy the assignments of the previous app.
Each upgrade therefore follows the same sequence as the first deployment in [Deploy the kong-harnesses Windows installer with Intune](/kong-harnesses/deploy-with-intune/):

1. Package the new `.msi` installer and add it as a new app for the same processor type.
1. Configure supersedence so the new app targets the previous release's app.
1. Assign the new app to a one-device test group that already runs the previous release, and confirm the in-place upgrade.
1. Assign the remaining groups, then clean up the previous app.

## Requirements

{% table %}
columns:
  - title: "Requirement"
    key: c0
  - title: "Details"
    key: c1
rows:
  - c0: "Existing app"
    c1: "A kong-harnesses Windows app (Win32) deployed with [Deploy the kong-harnesses Windows installer with Intune](/kong-harnesses/deploy-with-intune/) for the processor type you're upgrading."
  - c0: "Intune permissions"
    c1: "**Read**, **Create**, **Assign**, **Update**, **Delete**, and **Relate** for **Mobile apps**. The built-in Application Manager role includes these permissions."
  - c0: "Test group"
    c1: "One Windows 11 device that already runs the previous release, or the user of that device."
  - c0: "New installer"
    c1: "The new `.msi` installer for each processor type, verified with [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file)."
{% endtable %}

## Add the new app

Package the new installer and create the app with the same values as the first deployment.
See [Package the installer](/kong-harnesses/deploy-with-intune/#package-the-installer) and [Win32 app settings](/kong-harnesses/deploy-with-intune/#win32-app-settings), and put the new release in the app name, for example `kong-harnesses v1.2.4 x64`.

## Supersedence settings

On the **Supersedence** page of the wizard, use the following values.
For how supersedence works, see [Add Win32 app supersedence](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-supersedence).

{% table %}
columns:
  - title: "Setting"
    key: c0
  - title: "Value"
    key: c1
rows:
  - c0: "Superseded app"
    c1: "The previous release's app for the same processor type."
  - c0: "**Uninstall previous version**"
    c1: "Disabled, because the new `.msi` upgrades the installed version in place."
  - c0: "**Required** assignment"
    c1: "The one-device test group that runs the previous release. Add the remaining groups only after the upgrade passes on that device."
{% endtable %}

## Verify the test device

{% include kong-harnesses/intune-verify-device.md app="the new app" process="upgrade" release="the new release" %}

## Roll out and clean up

After the test device passes, add the remaining groups to the new app's **Required** assignments.
Wait until every assigned device or user reports `Installed` before you clean up the previous app.

Intune allows at most 11 apps in a [supersedence graph](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-supersedence#supersedence-limitations).
The limit counts the new app and up to 10 superseded apps, including apps superseded through earlier releases, so each release uses one of those slots until you remove the old app.

Clean up the previous app in this order:

1. Remove all assignments from the previous app.
1. Edit the new app's supersedence to remove the previous app.
1. Delete the previous app.

Removing the supersedence link first ensures that the new app stops referencing the app you delete.

## Verify the upgrade

In the [Microsoft Intune admin center](https://intune.microsoft.com), navigate to **Apps** > **All apps**, and confirm that only the active kong-harnesses release app remains for the processor type you upgraded.
Then repeat [Verify the test device](#verify-the-test-device) on a managed Windows 11 device, and confirm that **Device install status** (or **User install status**) shows `Installed` for every assigned device or user.
