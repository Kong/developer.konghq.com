---
title: Deploy the kong-harnesses Windows installer with Intune
description: How the kong-harnesses Windows installer is packaged as a Win32 app and deployed to managed Windows 11 computers with Microsoft Intune, with the settings to use and links to the Microsoft documentation.
content_type: reference
layout: reference
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

related_resources:
  - text: Upgrade the kong-harnesses Windows installer with Intune
    url: /kong-harnesses/upgrade-with-intune/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: Remove kong-harnesses
    url: /kong-harnesses/remove-kong-harnesses/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Add a Win32 app to Microsoft Intune
    url: https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32
  - text: Assign apps to groups with Microsoft Intune
    url: https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-deploy
  - text: Monitor apps
    url: https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-monitor
  - text: Microsoft Win32 Content Prep Tool
    url: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
---

Administrators who manage Windows 11 computers with [Microsoft Intune](https://learn.microsoft.com/en-us/intune/) can install [kong-harnesses](/kong-harnesses/) for every user of each computer without visiting the computer.
Intune installs the kong-harnesses `.msi` installer as a Windows app (Win32), the same installer that [Install kong-harnesses for every user of a computer](/kong-harnesses/install/) describes for manual installation.

The following sections give the packaging command, the settings to use for kong-harnesses, and the checks that confirm the result.
The linked Microsoft documentation covers the Intune interface, including every page of the app wizard.

## How the deployment works

Kong releases don't include an `.intunewin` file, which is the package format Intune requires for Win32 apps.
You wrap the `.msi` installer yourself with Microsoft's Win32 Content Prep Tool, then add the result to Intune as a new app.

- **One app for each processor type and release:** The x64 installer (`_windows_amd64.msi`) and the Arm installer (`_windows_arm64.msi`) replace each other, so each runs only on its own architecture.
  Add a separate app for each processor type that you manage.
  Each new release is also a new app, as described in [Upgrade the kong-harnesses Windows installer with Intune](/kong-harnesses/upgrade-with-intune/).
- **System-wide installation:** The installer places `kong-harnesses.exe` in `C:\Program Files\Kong\kong-harnesses\` and adds it to the system `PATH` for every user.
- **Test first:** A new app doesn't have assignments until you add them.
  Assign it to a group with a single device, confirm the installation there, and only then assign the remaining groups.

## Requirements

{% table %}
columns:
  - title: "Requirement"
    key: c0
  - title: "Details"
    key: c1
rows:
  - c0: "Intune permissions"
    c1: "**Read**, **Create**, **Assign**, **Update**, and **Delete** for **Mobile apps**. The built-in Application Manager role includes these permissions."
  - c0: "Managed devices"
    c1: "Windows 11 devices, or their users, that meet the [Win32 app prerequisites](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32#prerequisites). Each device is joined or registered to Microsoft Entra ID and enrolled in Intune. kong-harnesses doesn't support Windows 10."
  - c0: "Installer"
    c1: "The `.msi` installer for each processor type, verified with [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file)."
  - c0: "Packaging tool"
    c1: "The [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool) (`IntuneWinAppUtil.exe`)."
{% endtable %}

## Package the installer

Place the verified `.msi` file alone in an empty folder, then run the Content Prep Tool from PowerShell.
Replace `SOURCE_FOLDER` and `OUTPUT_FOLDER` with full paths and `FILE` with the `.msi` filename.
`OUTPUT_FOLDER` must be a different folder than `SOURCE_FOLDER`.

```powershell
.\IntuneWinAppUtil.exe -c 'SOURCE_FOLDER' -s 'SOURCE_FOLDER\FILE' -o 'OUTPUT_FOLDER'
```

The tool writes a `.intunewin` file into `OUTPUT_FOLDER`.
For the tool's options, see the [Content Prep Tool repository](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool).

## Win32 app settings

In the [Microsoft Intune admin center](https://intune.microsoft.com), create the app by following [Add a Win32 app to Microsoft Intune](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-win32), and use the following values for kong-harnesses.
Leave any setting that the table doesn't list at its default.

{% table %}
columns:
  - title: "Wizard page"
    key: c0
  - title: "Setting"
    key: c1
  - title: "Value"
    key: c2
rows:
  - c0: "App information"
    c1: "App package file"
    c2: "The `.intunewin` file from [Package the installer](#package-the-installer)."
  - c0: "App information"
    c1: "Name"
    c2: "A name that includes the release and processor type, for example `kong-harnesses v1.2.3 x64`."
  - c0: "App information"
    c1: "Description"
    c2: "`Installs kong-harnesses for every user of the computer`."
  - c0: "App information"
    c1: "Publisher"
    c2: "`Kong Inc.` if Intune leaves the field empty."
  - c0: "Program"
    c1: "Install and uninstall commands"
    c2: "The commands that Intune reads from the installer."
  - c0: "Program"
    c1: "Install behavior"
    c2: "**System**"
  - c0: "Program"
    c1: "Device restart behavior"
    c2: "**No specific action**, so the installation doesn't restart the device."
  - c0: "Requirements"
    c1: "Check operating system architecture"
    c2: "**Yes**. Select **Install on x64 system** for `_windows_amd64.msi`, or **Install on ARM64 system** for `_windows_arm64.msi`. Clear every other architecture."
  - c0: "Requirements"
    c1: "Minimum operating system"
    c2: "The oldest Windows 11 release in the list."
  - c0: "Detection rules"
    c1: "Rules format"
    c2: "**Manually configure detection rules** with one **MSI** rule that keeps the product code Intune reads from the installer."
  - c0: "Dependencies, Scope tags"
    c1: "All settings"
    c2: "Keep the defaults."
  - c0: "Supersedence"
    c1: "All settings"
    c2: "None for a first deployment. See [Upgrade the kong-harnesses Windows installer with Intune](/kong-harnesses/upgrade-with-intune/) for later releases."
  - c0: "Assignments"
    c1: "**Required** group"
    c2: "A test group with one device, or with the user of one device."
{% endtable %}

For how assignments work, see [Assign apps to groups with Microsoft Intune](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-deploy).

## Verify the test device

{% include kong-harnesses/intune-verify-device.md app="the app" process="installation" release="the release that you added to Intune" %}

## Roll out to the remaining groups

After the test device passes, edit the app's **Required** assignments in the Intune admin center and add the remaining groups.
Repeat [Verify the test device](#verify-the-test-device) on a sample of the newly assigned devices, and confirm that **Device install status** (or **User install status**) shows `Installed` for every assigned device or user.

## Remove kong-harnesses

Intune's **Uninstall** assignment removes kong-harnesses only from devices where that Intune app installed it through a **Required** or **Available for enrolled devices** assignment.
To remove it:

1. Ask each developer to remove their sign-ins, agent CLI settings, and profiles with [Remove kong-harnesses](/kong-harnesses/remove-kong-harnesses/).
   Developers need kong-harnesses installed to run those steps, so confirm that they have finished before you continue.
1. In the app's assignments, remove each **Required** group and add the same groups under **Uninstall**.
1. If you deployed apps for both processor types, repeat for the other app.

For copies that the Intune app didn't install, follow [Remove from Windows](/kong-harnesses/install/#remove-from-windows) on each device.
