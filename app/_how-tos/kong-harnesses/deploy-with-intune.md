---
title: Deploy the kong-harnesses Windows installer with Intune
description: Wrap the kong-harnesses Windows installer, add it to Microsoft Intune as a Windows app (Win32), and replace it with each new release.
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

automated_tests: false

tldr:
  q: How do I deploy kong-harnesses to Windows computers with Intune?
  a: |
    Wrap the checked Windows installer with the Microsoft Win32 Content Prep Tool, and add the `.intunewin` file to Intune as a Windows app (Win32) with an MSI detection rule and a **Required** assignment. For each new release, add a new app that supersedes the app of the previous release.

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
        You need an account that can add and assign apps in the [Microsoft Intune admin center](https://intune.microsoft.com), and a group of Windows 11 devices or users that need kong-harnesses.
    - title: kong-harnesses Windows installer
      content: |
        Download the file that ends in `_windows_amd64.msi` for x64 computers, or in `_windows_arm64.msi` for Arm computers, and check it as in [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file).
        Releases don't include an `.intunewin` file, so you wrap the installer yourself.
        Add one Windows app (Win32) for each processor type.
---

## Wrap the installer

1. Put the checked installer alone in an empty folder.
1. Download the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool), and open PowerShell in the folder that contains `IntuneWinAppUtil.exe`.
1. Wrap the installer:

   ```powershell
   .\IntuneWinAppUtil.exe -c '<folder>' -s '<folder>\<file>' -o '<output-folder>'
   ```

   Use full paths. `<file>` is the filename of the installer. `<output-folder>` must be a folder other than `<folder>`.

## Add the app in Intune

Add the app in the Microsoft Intune admin center. If Intune shows a **Scope tags** page between the pages of these steps, click **Next** on that page.

1. Navigate to **Apps** > **All Apps**.
1. Click **Create**.
1. In the **Select app type** pane, select **Windows**.
1. Select **Windows app (Win32)**.
1. Click **Select**.
1. On the **App information** page, click **Select app package file**.
1. In the **App package file** pane, click the browse button.
1. Select the `.intunewin` file.
1. Click **OK**.
1. In the **Name** field, enter a name that contains the release and the processor type, for example `kong-harnesses v1.2.3 x64`.
1. Click **Edit description**.
1. In the description field, enter `Installs kong-harnesses for every user of the computer`.
1. Click **OK**.
1. In the **Publisher** field, enter `Kong Inc.` if the field is empty.
1. Click **Next**.
1. On the **Program** page, keep the install and uninstall commands that Intune reads from the installer.
1. In the **Install behavior** section, select **System**.
1. From the **Device restart behavior** dropdown menu, select "No specific action". This setting stops the install from restarting the device.
1. Click **Next**.
1. On the **Requirements** page, in the **Check operating system architecture** section, select **Yes. Specify the systems the app can be installed on.**
1. Select the **Install on x64 system** checkbox for the `_windows_amd64.msi` installer, or the **Install on ARM64 system** checkbox for the `_windows_arm64.msi` installer. Make sure that no other architecture checkbox is selected, because the two installers replace each other.
1. From the **Minimum operating system** dropdown menu, select the oldest Windows 11 release in the list. kong-harnesses doesn't support Windows 10.
1. Click **Next**.
1. On the **Detection rules** page, from the **Rules format** dropdown menu, select "Manually configure detection rules".
1. Click **Add**.
1. From the **Rule type** dropdown menu, select "MSI". Keep the product code that Intune reads from the installer.
1. Click **OK**.
1. Click **Next**.
1. On the **Dependencies** page, click **Next**.
1. On the **Supersedence** page, for a new release, add the app of the previous release. Skip these steps for the first release:
   1. Click **Add**.
   1. In the **Add Apps** pane, select the app of the previous release for the same processor type.
   1. Click **Select**.
   1. Disable **Uninstall previous version**. The new installer upgrades the installed version in place, so Intune doesn't need to remove the previous version first.
1. Click **Next**.
1. On the **Assignments** page, under **Required**, click **Add group**.
1. Select the groups of devices or users that need kong-harnesses. A new app doesn't copy the assignments of the previous app, so select the same groups for each release.
1. Click **Select**.
1. Click **Next**.
1. On the **Review + create** page, click **Create**.

## Replace the app for each new release

Add a new app in the same way for each new release. Intune allows at most 10 superseded apps in a supersedence graph, including apps that the new app supersedes through other apps, and each release adds one.

When all assigned devices run the new release, remove the assignments of the previous app. Then open the **Properties** of the new app, click **Edit** next to **Supersedence**, remove the previous app, click **Review + save** and **Save**, and delete the previous app.

To remove kong-harnesses from the devices, see the removal steps in [Windows installer](/kong-harnesses/install/#windows-installer).

## Validate

When Intune reports the install on a test device as successful, check the installation on that device. In PowerShell, run:

```powershell
(Get-Command kong-harnesses).Source
```

The command must print `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`. Then check the release:

{% validation custom-command %}
command: kong-harnesses version
expected:
  return_code: 0
render_output: false
{% endvalidation %}

The version must be the release that you added to Intune.
