---
title: Deploy the kong-harnesses Windows installer with Intune
description: Wrap the kong-harnesses Windows installer as a Win32 app, deploy it to managed Windows 11 computers with Microsoft Intune, and upgrade it with supersedence.
content_type: how_to
permalink: /kong-harnesses/deploy-with-intune/
breadcrumbs:
  - /kong-harnesses/

products:
  - ai-gateway

works_on:
  - konnect

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
    Validate the install on the test device before assigning remaining groups.
    For each new release, add a new app that supersedes the previous release.

related_resources:
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/

prereqs:
  skip_product: true
  inline:
    - title: Microsoft Intune
      content: |
        You need an account in the [Microsoft Intune admin center](https://intune.microsoft.com) with **Read**, **Create**, **Assign**, **Update**, and **Delete** permissions for **Mobile apps**.
        To configure supersedence for new releases, the account also needs the **Relate** permission for **Mobile apps**.
        The built-in Application Manager role includes these permissions.

        You also need a group of Windows 11 devices, or their users, that meet the [Win32 app prerequisites](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32#prerequisites): each device is joined or registered to Microsoft Entra ID and enrolled in Intune.
    - title: kong-harnesses Windows installer
      content: |
        Download `_windows_amd64.msi` for x64 computers or `_windows_arm64.msi` for Arm computers, and verify it using [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file).
        Releases don't include an `.intunewin` file, so wrap the installer yourself and add one Windows app (Win32) for each processor type.

cleanup:
  inline:
    - title: Remove kong-harnesses from Intune-managed devices
      content: |
        1. Ask each developer on the managed devices to remove their agent CLI settings, sign-ins, and profiles using [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).
        1. In the Microsoft Intune admin center, remove the target groups from the **Required** assignment and assign them under **Uninstall**, or remove the **Required** assignment and follow [Remove from Windows](/kong-harnesses/install/#remove-from-windows) on each device.
---

## Wrap the installer

Package the verified `.msi` file into an `.intunewin` archive before uploading it to Intune.

1. Place the verified `.msi` installer alone in an empty folder.
1. Download the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool), then open PowerShell in the folder containing `IntuneWinAppUtil.exe`.
1. Wrap the installer into an `.intunewin` package, replacing `SOURCE_FOLDER` and `OUTPUT_FOLDER` with full paths (`OUTPUT_FOLDER` must be a different folder than `SOURCE_FOLDER`) and `FILE` with the `.msi` filename:

   ```powershell
   .\IntuneWinAppUtil.exe -c 'SOURCE_FOLDER' -s 'SOURCE_FOLDER\FILE' -o 'OUTPUT_FOLDER'
   ```

   The tool writes a `.intunewin` package file into `OUTPUT_FOLDER`.

## Add the app in Intune

Create a Windows app (Win32) in the [Microsoft Intune admin center](https://intune.microsoft.com) and assign it to a one-device test group first.

{:.info}
> If Intune shows a **Scope tags** page between wizard pages, click **Next**.

### Upload the package and enter app details

1. Navigate to **Apps** > **All apps**.
1. Click **Create**.
1. In the **Select app type** pane, select **Windows**.
1. Select **Windows app (Win32)**.
1. Click **Select**.
1. On the **App information** page, click **Select app package file**.
1. In the **App package file** pane, click the browse button.
1. Select the `.intunewin` file.
1. Click **OK**.
1. In the **Name** field, enter a name that includes the release and processor type, for example `kong-harnesses v1.2.3 x64`.
1. Click **Edit Description**.
1. In the description field, enter `Installs kong-harnesses for every user of the computer`.
1. Click **OK**.
1. In the **Publisher** field, enter `Kong Inc.` if the field is empty.
1. Click **Next**.

### Configure program, requirements, and detection

1. On the **Program** page, keep the install and uninstall commands that Intune reads from the installer.
1. In the **Install behavior** section, select **System**.
1. From the **Device restart behavior** dropdown menu, select "No specific action".
   This setting prevents the installation from restarting the device.
1. Click **Next**.
1. On the **Requirements** page, in the **Check operating system architecture** section, select **Yes. Specify the systems the app can be installed on.**
1. Select the **Install on x64 system** checkbox for `_windows_amd64.msi`, or select the **Install on ARM64 system** checkbox for `_windows_arm64.msi`.
   Make sure no other architecture checkbox is selected, because the two installers replace each other.
1. From the **Minimum operating system** dropdown menu, select the oldest Windows 11 release in the list.
   kong-harnesses doesn't support Windows 10.
1. Click **Next**.
1. On the **Detection rules** page, from the **Rules format** dropdown menu, select "Manually configure detection rules".
1. Click **Add**.
1. From the **Rule type** dropdown menu, select "MSI".
   Keep the product code that Intune reads from the installer.
1. Click **OK**.
1. Click **Next**.
1. On the **Dependencies** page, click **Next**.

### Assign the app to a test group

1. On the **Supersedence** page, click **Next**.
1. On the **Assignments** page, under **Required**, click **Add group**.
1. Select a test group with one device, or with the user of one device.
   Add the remaining groups only after [Validate](#validate) passes on that device.
1. Click **Select**.
1. Click **Next**.
1. On the **Review + create** page, click **Create**.

## Validate

Confirm that Intune installed the expected release on the test device before rolling out the app broadly.

1. Wait until Intune reports the installation on the test device as successful, then open a new PowerShell window on that device.
   The installer updates the system `PATH`, which a PowerShell window opened before the installation doesn't see.
1. Confirm that PowerShell resolves the system-wide executable:

   ```powershell
   (Get-Command kong-harnesses).Source
   ```

   The command must print `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.
1. Verify the installed release version:

   {% validation custom-command %}
   command: kong-harnesses version
   expected:
     return_code: 0
   render_output: false
   indent: 3
   {% endvalidation %}

   The command prints the release added to Intune with its leading `v`, for example `v1.2.3`.

## Roll out to remaining groups

After validation passes on the test device, assign the app to the remaining groups that need kong-harnesses:

1. In the Microsoft Intune admin center, navigate to **Apps** > **All apps**.
1. Click the app name.
1. Click **Properties**.
1. Next to **Assignments**, click **Edit**.
1. Under **Required**, click **Add group**.
1. Select the remaining groups.
1. Click **Select**.
1. Click **Review + save**.
1. Click **Save**.

## Upgrade to a new release

Add a new Windows app (Win32) for each new release using the same workflow, with supersedence configured to upgrade the previous app in place.
A new app doesn't copy the assignments of the previous app, so test each new release on the test group first and add the same groups after validation passes.

1. Complete [Wrap the installer](#wrap-the-installer) and [Add the app in Intune](#add-the-app-in-intune) through the **Dependencies** page.
1. On the **Supersedence** page, click **Add**.
1. In the **Add Apps** pane, select the previous release's app for the same processor type.
1. Click **Select**.
1. Disable **Uninstall previous version**.
   The new `.msi` upgrades the installed version in place, so Intune doesn't need to uninstall the previous version first.
1. Click **Next**.
1. Complete steps 2 through 6 of [Assign the app to a test group](#assign-the-app-to-a-test-group).
1. Confirm the upgrade on the test device using [Validate](#validate).
1. Assign the new app to the remaining groups using [Roll out to remaining groups](#roll-out-to-remaining-groups).

Intune allows at most 11 apps in a [supersedence graph](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-supersedence#supersedence-limitations), counting the new app and up to 10 superseded apps (including apps superseded through earlier releases), and each release adds one.
Remove each previous app once all assigned devices run the new release:

1. In the Microsoft Intune admin center, navigate to **Apps** > **All apps**.
1. Click the previous app.
1. Click **Properties**.
1. Next to **Assignments**, click **Edit**.
1. Remove each assigned group.
1. Click **Review + save**.
1. Click **Save**.
1. Navigate to **Apps** > **All apps**.
1. Click the new app.
1. Click **Properties**.
1. Next to **Supersedence**, click **Edit**.
1. Remove the previous app from the supersedence list.
1. Click **Review + save**.
1. Click **Save**.
1. Navigate to **Apps** > **All apps**.
1. Delete the previous app.
