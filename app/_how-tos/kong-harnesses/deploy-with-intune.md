---
title: Deploy the kong-harnesses Windows installer with Intune
description: Wrap the kong-harnesses Windows installer as a Win32 app and deploy it to managed Windows 11 computers with Microsoft Intune.
content_type: how_to
permalink: /kong-harnesses/deploy-with-intune/
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

automated_tests: false

tldr:
  q: How do I deploy kong-harnesses to Windows computers with Intune?
  a: |
    Wrap the verified `.msi` installer with the Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`).
    Add the `.intunewin` file to Intune as a Windows app (Win32) with **System** install behavior, an MSI detection rule, and a **Required** assignment to a one-device test group.
    Test the installation on that device, then assign the remaining groups and validate the rollout.

related_resources:
  - text: Upgrade the kong-harnesses Windows installer with Intune
    url: /kong-harnesses/upgrade-with-intune/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Microsoft Intune
      content: |
        You need an account in the [Microsoft Intune admin center](https://intune.microsoft.com) with **Read**, **Create**, **Assign**, **Update**, and **Delete** permissions for **Mobile apps**.
        The built-in Application Manager role includes these permissions.

        You also need a group of Windows 11 devices, or their users, that meet the [Win32 app prerequisites](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32#prerequisites).
        Each device is joined or registered to Microsoft Entra ID and enrolled in Intune.
    - title: kong-harnesses Windows installer
      content: |
        Download `_windows_amd64.msi` for x64 computers or `_windows_arm64.msi` for Arm computers, and verify it using [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file).
        Releases don't include an `.intunewin` file, so wrap the installer yourself and add one Windows app (Win32) for each processor type.

cleanup:
  inline:
    - title: Remove kong-harnesses from Intune-managed devices
      content: |
        1. Ask each developer on the managed devices to remove their sign-ins, agent CLI settings, and profiles using [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).
           Confirm that developers have finished before you assign **Uninstall**, because they need kong-harnesses installed to run those steps.
        1. In the [Microsoft Intune admin center](https://intune.microsoft.com), navigate to **Apps** > **All apps**.
        1. Click the kong-harnesses app for a deployed processor type (x64 or Arm64).
        1. Click **Properties**.
        1. Next to **Assignments**, click **Edit**.
        1. Under **Required**, click **Remove** on each target group row.
        1. Under **Uninstall**, click **Add group**.
        1. Select the same groups.
        1. Click **Select**.
        1. Click **Review + save**.
        1. Click **Save**.
        1. If you deployed apps for both x64 and Arm64 devices, repeat the Intune steps from **Apps** > **All apps** for the other processor-type app.

        Intune's **Uninstall** assignment removes kong-harnesses only on devices where that Intune app installed it through a **Required** or **Available for enrolled devices** assignment.
        For copies installed outside the Intune app, follow [Remove from Windows](/kong-harnesses/install/#remove-from-windows) on each device.
---

## Wrap the installer

{% include how-tos/steps/kong-harnesses-intune-wrap.md %}

## Add the app in Intune

Create a Windows app (Win32) in the [Microsoft Intune admin center](https://intune.microsoft.com) and assign it to a one-device test group first.

### Upload the package and enter app details

{% include how-tos/steps/kong-harnesses-intune-upload.md %}

### Configure program, requirements, and detection

{% include how-tos/steps/kong-harnesses-intune-configure.md %}

### Assign the app to a test group

1. On the **Supersedence** page, click **Next**.
1. On the **Assignments** page, under **Required**, click **Add group**.
1. Select a test group with one device, or with the user of one device.
   Add the remaining groups only after [Test the installation on the test device](#test-the-installation-on-the-test-device) passes.
1. Click **Select**.
1. Click **Next**.
1. On the **Review + create** page, click **Create**.

## Test the installation on the test device

Confirm that Intune installed the expected release on the test device before rolling out the app broadly.

1. Under **Monitor** > **Device install status** for the app, wait until the test device reports `Installed`.
   If you assigned a user group, check **User install status** instead.
1. Open a new PowerShell window on the test device.
   The installer updates the system `PATH`, which a PowerShell window opened before the installation doesn't see.
1. Confirm that PowerShell resolves the system-wide executable:

   ```powershell
   (Get-Command kong-harnesses).Source
   ```

   The command prints `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.
1. Verify the installed release version:

   ```powershell
   kong-harnesses version
   ```

   The command prints the release added to Intune with its leading `v`, for example `v1.2.3`.

## Roll out to remaining groups

{% include how-tos/steps/kong-harnesses-intune-rollout.md %}

## Validate

Confirm that Intune installed kong-harnesses on the assigned Windows 11 computers and that the executable reports the deployed release.

1. In the [Microsoft Intune admin center](https://intune.microsoft.com), navigate to **Apps** > **All apps**.
1. Click the kong-harnesses app name.
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

   The command prints the release added to Intune with its leading `v`, for example `v1.2.3`.
