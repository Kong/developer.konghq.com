---
title: Install Insomnia on Windows
content_type: how_to
products:
- insomnia
description: Learn how to install Insomnia on a Windows device.
tags:
  - insomnia
  - install
  - windows

breadcrumbs:
  - /insomnia/

min_version:
  insomnia: '11.3.0'

prereqs:
  skip_product: true
  inline:
    - title: "Windows"
      content: |
        To install and run Insomnia on Windows, you need Windows 10 or later.
      icon_url: /assets/icons/third-party/windows.svg

tldr:
  q: How do I download Insomnia on a Windows device?
  a: Go to the [latest Insomnia release](https://github.com/Kong/insomnia/releases/tag/core%40{{ site.data.insomnia_latest.version }}) on GitHub and download `Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe` file.
faqs:
  - q: How do I specify a custom directory during a silent install?
    a: |
      To specify a custom directory, add `/D=path`:
      ```powershell
      Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S /D=C:\Insomnia
      ```
  - q: How do I change the default installation path? 
    a: |
      You can use the `/D=` flag if you want to change the default installation path.  
      If not specified, Insomnia installs to the following directories:
      - **System-wide installation**: `C:\Program Files\Insomnia`  
      - **Per-user installation**: `C:\Users\$USERNAME\AppData\Local\Programs\Insomnia`  
      
      Use `/D=your_path` only when you want to specify a custom installation directory.
     
next_steps:
  - text: Get started with documents
    url: /insomnia/documents/
  - text: Get started with collections
    url: /insomnia/collections/

no_wrap: true    
---

Insomnia for Windows offers two installers:
- **Desktop Install**: Run the installation application and follow the steps in the installation wizard.
- **Silent Install**: Run the application from the command line with the `/S` argument and optional parameters to install without user interaction.

## Install Insomnia

{% navtabs "windows install" %}
{% navtab "Desktop install" %}

Before you install, close any open Insomnia applications. The installer can't update files that are actively in use.

1. Go to the [latest Insomnia release](https://github.com/Kong/insomnia/releases/tag/core%40{{ site.data.insomnia_latest.version }}) on GitHub.
1. From the **Assets** section, click `Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe` to download the installer.
1. From your downloads folder, select the `Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe` file.
1. Click **Yes** to run the installer.
{% endnavtab %}
{% navtab "Silent install" %}
After installing the installer, run the installer with the `/S` flag to perform a silent installation:

```powershell
Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S
```

Silent installs use default options unless specifically overridden. 
To specify a custom directory, add `/D=path`: 

```powershell
Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S /D=C:\Insomnia
```

{% endnavtab %}
{% navtab "Admin install" %}

For system-wide installations, run the installer with administrator privileges:

```powershell
Insomnia.Core-nsis-{{ site.data.insomnia_latest.version }}.exe /S /D="C:\Program Files\Insomnia"
```
{% endnavtab %}
{% endnavtabs %}


## Uninstall Insomnia
Before uninstalling, make sure all Insomnia windows are closed.

If the app is still running, the uninstall may not complete successfully.

{% navtabs "Uninstall" %}
{% navtab "Uninstall via settings" %}

1. On your Windows device, go to **Settings > Apps > Installed apps**.
1. Find Insomnia in the list of installed applications and select the ellipsis (⋯).
1. Click **Uninstall**.
1. Click **Finish**.

{% endnavtab %}
{% navtab "Uninstall silently (optional)" %}
To uninstall Insomnia silently, run the uninstaller with the /S flag:

```powershell
"%ProgramFiles%\Insomnia\Uninstall.exe" /S
```
{% endnavtab %}
{% endnavtabs %}