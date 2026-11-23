---
title: Upgrade the kong-harnesses Windows installer with Intune
description: Add a new kong-harnesses release to Microsoft Intune with supersedence, roll it out to managed Windows 11 computers, and clean up the previous release app.
content_type: how_to
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

automated_tests: false

tldr:
  q: How do I upgrade kong-harnesses on Windows computers with Intune?
  a: |
    Wrap the new `.msi` installer with `IntuneWinAppUtil.exe` and add it to Intune as a new Windows app (Win32) for the same processor type.
    Configure supersedence targeting the previous release app with **Uninstall previous version** disabled, test the upgrade on a one-device test group, and then assign the remaining groups.
    After all assigned devices report `Installed`, remove the previous app's assignments, unlink it from supersedence, and delete it.

related_resources:
  - text: Deploy the kong-harnesses Windows installer with Intune
    url: /kong-harnesses/deploy-with-intune/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Microsoft Intune and an existing kong-harnesses app
      content: |
        You need an existing kong-harnesses Windows app (Win32) deployed through [Deploy the kong-harnesses Windows installer with Intune](/kong-harnesses/deploy-with-intune/) for the processor type you're upgrading.
        You also need an account in the [Microsoft Intune admin center](https://intune.microsoft.com) with **Read**, **Create**, **Assign**, **Update**, **Delete**, and **Relate** permissions for **Mobile apps**.
        The built-in Application Manager role includes these permissions.

        Use a test group with one Windows 11 device that already runs the previous release of kong-harnesses, or with the user of that device.
        Testing the upgrade on one device first lets you confirm the in-place upgrade before assigning the remaining groups.
    - title: New kong-harnesses Windows installer
      content: |
        Download the new `_windows_amd64.msi` for x64 computers or `_windows_arm64.msi` for Arm computers, and verify it using [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file).
        Releases don't include an `.intunewin` file, so wrap each release yourself and add one Windows app (Win32) for each processor type.
---

Upgrading kong-harnesses in Microsoft Intune uses a new Windows app (Win32) with supersedence targeting the previous release app for the same processor type.
A new app doesn't copy the assignments of the previous app, so test each new release on a one-device test group before assigning the remaining groups.

## Wrap the installer

{% include how-tos/steps/kong-harnesses-intune-wrap.md %}

## Add the new app with supersedence

Create a Windows app (Win32) in the [Microsoft Intune admin center](https://intune.microsoft.com) for the new release and configure it to supersede the previous app in place.

### Upload the package and enter app details

{% include how-tos/steps/kong-harnesses-intune-upload.md %}

### Configure program, requirements, and detection

{% include how-tos/steps/kong-harnesses-intune-configure.md %}

### Configure supersedence and assign to a test group

1. On the **Supersedence** page, click **Add**.
1. In the **Add Apps** pane, select the previous release's app for the same processor type.
1. Click **Select**.
1. Disable **Uninstall previous version**.
   The new `.msi` upgrades the installed version in place, so Intune doesn't need to uninstall the previous version first.
1. Click **Next**.
1. On the **Assignments** page, under **Required**, click **Add group**.
1. Select the one-device test group running the previous release.
   Add the remaining groups only after verifying the upgrade on that device.
1. Click **Select**.
1. Click **Next**.
1. On the **Review + create** page, click **Create**.

## Test the upgrade on the test device

Confirm that Intune upgraded kong-harnesses on the test device before rolling out the new release broadly.

1. Under **Monitor** > **Device install status** for the app, wait until the test device reports `Installed`.
   If you assigned a user group, check **User install status** instead.
1. Open a new PowerShell window on the test device.
1. Confirm that PowerShell resolves the system-wide executable:

   ```powershell
   (Get-Command kong-harnesses).Source
   ```

   The command prints `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.
1. Verify that the installed release matches the new version:

   ```powershell
   kong-harnesses version
   ```

   The command prints the new release version with its leading `v`, for example `v1.2.3`.

## Roll out to remaining groups

{% include how-tos/steps/kong-harnesses-intune-rollout.md %}

Wait until all assigned devices report `Installed` under **Monitor** > **Device install status** before cleaning up the previous app.
If you assigned user groups, check **User install status** instead.

## Clean up the previous app

Intune allows at most 11 apps in a [supersedence graph](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-supersedence#supersedence-limitations).
The limit counts the new app and up to 10 superseded apps, including apps superseded through earlier releases.
Each release adds one app.

After all assigned devices report `Installed` for the new release, clean up the previous app from **Apps** > **All apps** in the [Microsoft Intune admin center](https://intune.microsoft.com).

### Remove the previous app's assignments

1. In the [Microsoft Intune admin center](https://intune.microsoft.com), navigate to **Apps** > **All apps**.
1. Click the previous app.
1. Click **Properties**.
1. Next to **Assignments**, click **Edit**.
1. On each assigned group row, click **Remove**.
1. Click **Review + save**.
1. Click **Save**.

### Remove the previous app from supersedence

1. Navigate to **Apps** > **All apps**.
1. Click the new app.
1. Click **Properties**.
1. Next to **Supersedence**, click **Edit**.
1. Click the action menu icon on the row of the previous app.
1. Click **Delete**.
1. Click **Review + save**.
1. Click **Save**.

### Delete the previous app

1. Navigate to **Apps** > **All apps**.
1. Click the action menu icon on the row of the previous app.
1. Click **Delete**.
1. Click **Yes**.

## Validate

Confirm that only the active kong-harnesses release app remains and that managed devices run the new release.

1. In the [Microsoft Intune admin center](https://intune.microsoft.com), navigate to **Apps** > **All apps**.
   Confirm that only the active kong-harnesses release app remains for the processor type you upgraded.
1. Click the active release app.
1. Under **Monitor**, click **Device install status**.
   If you assigned user groups, click **User install status** instead.
   Confirm that the assigned devices or users report `Installed`.
1. Open a new PowerShell window on a managed Windows 11 device.
1. Verify the installed release version:

   {% validation custom-command %}
   command: kong-harnesses version
   expected:
     return_code: 0
   render_output: false
   indent: 3
   {% endvalidation %}

   The command prints the new release version with its leading `v`, for example `v1.2.3`.
